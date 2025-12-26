# -----------------------------------------------------------
# MOBILE ORCHESTRATION — CLEAN & STABLE
# -----------------------------------------------------------

import uuid
import requests
from django.http import JsonResponse
from django.utils import timezone
from django.shortcuts import get_object_or_404

from rest_framework.decorators import api_view, authentication_classes, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework_simplejwt.authentication import JWTAuthentication
from rest_framework import status

from myproject.models import Beneficiary
from myproject.views import safe_value, calculate_eligibility
from myproject.households import assign_households
from .mobile_serializers import serialize_beneficiary
from .inform_api import submit_to_inform, fetch_inform_record


# ===========================================================
# 🔥 CENTRAL MOBILE ENDPOINT
# ===========================================================
@api_view(["POST"])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])
def orchestrate_mobile(request):
    data = request.data
    action = data.get("action")
    payload = data.get("payload")

    print("\n📥 ORCHESTRATE REQUEST")
    print("➡️ Action:", action)
    print("➡️ Payload keys:", payload.keys() if isinstance(payload, dict) else payload)

    if action not in {"create", "update", "delete", "restore"}:
        return JsonResponse(
            {"success": False, "error": "Invalid action"},
            status=status.HTTP_400_BAD_REQUEST,
        )

    if not isinstance(payload, dict):
        return JsonResponse(
            {"success": False, "error": "Invalid payload"},
            status=status.HTTP_400_BAD_REQUEST,
        )

    # Audit fields
    payload.setdefault("created_by", request.user.username)
    payload["updated_by"] = request.user.username
    payload.setdefault("deleted_by", request.user.username)
    payload.setdefault("undeleted_by", request.user.username)

    if action == "create":
        result = _handle_create(payload)
    elif action == "update":
        result = _handle_update(payload)
    elif action == "delete":
        result = _handle_delete(payload)
    else:
        result = _handle_restore(payload)

    print("📤 ORCHESTRATE RESULT:", result)

    return JsonResponse(
        result,
        status=status.HTTP_200_OK if result.get("success") else status.HTTP_409_CONFLICT,
        safe=True,
    )


# ===========================================================
# 🟢 CREATE
# ===========================================================
from django.db import transaction

def _handle_create(payload):
    print("🟢 API CREATE")

    try:
        with transaction.atomic():

            # -----------------------------
            # CREATE LOCAL RECORD
            # (ALL FIELDS OPTIONAL)
            # -----------------------------
            obj = Beneficiary.objects.create(
                IP_Name=safe_value(payload.get("IP_Name")),
                Sector=safe_value(payload.get("Sector")),
                Indicator=safe_value(payload.get("Indicator")),
                Date=safe_value(payload.get("Date")),
                Name=safe_value(payload.get("Name")),
                ID_Number=safe_value(payload.get("ID_Number")),
                Parent_ID=safe_value(payload.get("Parent_ID")),
                Spouse_ID=safe_value(payload.get("Spouse_ID")),
                Phone_Number=safe_value(payload.get("Phone_Number")),
                Date_of_Birth=safe_value(payload.get("Date_of_Birth")),
                Age=safe_value(payload.get("Age")),
                Gender=safe_value(payload.get("Gender")),
                Governorate=safe_value(payload.get("Governorate")),
                Municipality=safe_value(payload.get("Municipality")),
                Neighborhood=safe_value(payload.get("Neighborhood")),
                Site_Name=safe_value(payload.get("Site_Name")),
                Disability_Status=safe_value(payload.get("Disability_Status")),
                Supply_Type=safe_value(payload.get("Supply_Type")),
                Benefit_Date=safe_value(payload.get("Benefit_Date")),
                HH_Members=safe_value(payload.get("HH_Members")),
                Marital_Status=safe_value(payload.get("Marital_Status")),
                created_by = safe_value(payload.get("created_by")),
                created_at = timezone.now(),

            )

            # -----------------------------
            # CALCULATE ELIGIBILITY (SAFE)
            # -----------------------------
            obj.Eligiblity = calculate_eligibility(obj)
            obj.save(update_fields=["Eligiblity"])

            # -----------------------------
            # HOUSEHOLD ASSIGNMENT
            # -----------------------------
            assign_households()

        return {
            "success": True,
            "id": obj.id,
            "beneficiary": serialize_beneficiary(obj),
        }

    except Exception as e:
        return {
            "success": False,
            "error": str(e),
        }



# ===========================================================
# 🟡 UPDATE
# ===========================================================
from django.db import transaction
from django.shortcuts import get_object_or_404

def _handle_update(payload):
    print("🟡 API UPDATE")

    try:
        with transaction.atomic():

            # -------------------------------------------------
            # 1. IDENTIFY RECORD (prefer ID, fallback to ID_Number)
            # -------------------------------------------------
            obj = None

            if payload.get("id"):
                obj = get_object_or_404(Beneficiary, pk=payload.get("id"))

            elif payload.get("ID_Number"):
                obj = get_object_or_404(
                    Beneficiary,
                    ID_Number=safe_value(payload.get("ID_Number"))
                )

            else:
                return {
                    "success": False,
                    "error": "Missing identifier (id or ID_Number)",
                }

            # -------------------------------------------------
            # 2. UPDATE ONLY PROVIDED FIELDS
            # -------------------------------------------------
            FIELD_MAP = {
                "IP_Name": "IP_Name",
                "Sector": "Sector",
                "Indicator": "Indicator",
                "Date": "Date",
                "Name": "Name",
                "ID_Number": "ID_Number",
                "Parent_ID": "Parent_ID",
                "Spouse_ID": "Spouse_ID",
                "Phone_Number": "Phone_Number",
                "Date_of_Birth": "Date_of_Birth",
                "Age": "Age",
                "Gender": "Gender",
                "Governorate": "Governorate",
                "Municipality": "Municipality",
                "Neighborhood": "Neighborhood",
                "Site_Name": "Site_Name",
                "Disability_Status": "Disability_Status",
                "Supply_Type": "Supply_Type",
                "Benefit_Date": "Benefit_Date",
                "HH_Members": "HH_Members",
                "Marital_Status": "Marital_Status",
                "updated_by": "updated_by",
                "updated_at": "updated_at",
            }

            for payload_key, model_field in FIELD_MAP.items():
                if payload_key in payload:
                    setattr(
                        obj,
                        model_field,
                        safe_value(payload.get(payload_key))
                    )
            obj.save()

            # -------------------------------------------------
            # 3. RECALCULATE ELIGIBILITY
            # -------------------------------------------------
            obj.Eligiblity = calculate_eligibility(obj)
            obj.updated_by = safe_value(payload.get("updated_by")),
            obj.updated_at = timezone.now
            
            obj.save(update_fields=["Eligiblity","updated_by", "updated_at"])

            # -------------------------------------------------
            # 4. UPDATE HOUSEHOLDS
            # -------------------------------------------------
            assign_households()

        return {
            "success": True,
            "id": obj.id,
            "beneficiary": serialize_beneficiary(obj),
        }

    except Exception as e:
        print("❌ UPDATE FAILED:", str(e))
        return {
            "success": False,
            "error": str(e),
        }



# ===========================================================
# 🔴 DELETE
# ===========================================================
from django.db import transaction
from django.utils import timezone
from django.shortcuts import get_object_or_404

def _handle_delete(payload):
    pk = payload.get("id")
    if not pk:
        return {"success": False, "error": "Missing id"}

    try:
        with transaction.atomic():
            obj = get_object_or_404(Beneficiary.all_objects, pk=pk)

            # Prevent double delete
            if obj.Deleted:
                return {
                    "success": False,
                    "error": "Record already deleted",
                }

            obj.Deleted = True
            obj.deleted_at = timezone.now()
            obj.deleted_by = safe_value(payload.get("deleted_by"))

            
            obj.save()

        return {
            "success": True,
            "beneficiary": serialize_beneficiary(obj),
        }

    except Exception as e:
        return {
            "success": False,
            "error": str(e),
        }



# ===========================================================
# 🟣 RESTORE
# ===========================================================
def _handle_restore(payload):
    pk = payload.get("id")
    if not pk:
        return {"success": False, "error": "Missing id"}

    obj = get_object_or_404(Beneficiary.deleted_objects, pk=pk)

    obj.Deleted = False
    obj.undeleted_at = timezone.now()
    obj.undeleted_by = safe_value(payload.get("undeleted_by"))
    obj.save()

    return {"success": True, "beneficiary": serialize_beneficiary(obj)}


# ===========================================================
# 🔧 HELPERS
# ===========================================================
