# myproject/mobile_api/mobile_orchestration.py
from django.conf import settings

import json
import uuid
import requests
from datetime import datetime
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.db import transaction
from django.utils import timezone
from django.shortcuts import get_object_or_404

from myproject.models import Beneficiary, APIToken
from myproject.serializers import BeneficiarySerializer
from .mobile_serializers import serialize_beneficiary
from myproject.views import BeneficiaryPagination, safe_value
from myproject.households import assign_households
from django.core.paginator import Paginator
from .inform_api import (
    submit_to_inform,
    fetch_inform_record,
)

from rest_framework.permissions import IsAuthenticated
from rest_framework.decorators import api_view, permission_classes
from rest_framework_simplejwt.authentication import JWTAuthentication
from rest_framework.pagination import PageNumberPagination


# Pagination: 100 per page
class BeneficiaryPagination(PageNumberPagination):
    page_size = 100
    max_page_size = 1000

# -----------------------------------------------------------
# 🎯 CENTRAL ENDPOINT — ALL MOBILE OPERATIONS
# -----------------------------------------------------------
@api_view(["POST"])
@permission_classes([IsAuthenticated])
@csrf_exempt
def orchestrate_mobile(request):

    serializer_class = serialize_beneficiary
    authentication_classes = [JWTAuthentication]
    permission_classes = [permissions.IsAuthenticated]
    pagination_class = BeneficiaryPagination

    if request.method != "POST":
        return JsonResponse({"error": "Only POST allowed"}, status=405)

    try:
        data = json.loads(request.body.decode("utf-8"))
    except:
        return JsonResponse({"error": "Invalid JSON"}, status=400)

    action = data.get("action")
    payload = data.get("payload")

    if action not in ["create", "update", "delete", "restore"]:
        return JsonResponse({"error": f"Invalid action '{action}'"}, status=400)

    if not payload:
        return JsonResponse({"error": "Missing payload"}, status=400)

    # --------------------------
    # Route to correct function
    # --------------------------
    if action == "create":
        return _handle_create(payload)

    if action == "update":
        return _handle_update(payload)

    if action == "delete":
        return _handle_delete(payload)

    if action == "restore":
        return _handle_restore(payload)

    return JsonResponse({"error": "Unknown error"}, status=500)


# -----------------------------------------------------------
# 🟢 CREATE BENEFICIARY
# -----------------------------------------------------------
def _handle_create(payload):
    id_number = safe_value(payload.get("ID_Number"))

    # Duplicate check
    duplicates = Beneficiary.all_objects.filter(ID_Number=id_number)
    if duplicates.exists():
        return JsonResponse({
            "success": False,
            "duplicate": True,
            "message": f"Duplicate ID_Number {id_number}"
        }, status=409)

    # Build local object for initial POST
    instance_uuid = str(uuid.uuid4())
    instance_id = f"uuid:{instance_uuid}"

    # Prepare form data (local)
    form_data = _extract_local_fields(payload)
    form_data["created_by"] = payload.get("created_by")
    form_data["meta_instance_id"] = instance_id

    # -----------------------------
    # Submit to InForm API
    # -----------------------------
    inform_result = submit_to_inform(form_data)

    if not inform_result["success"]:
        return JsonResponse(inform_result, status=500)

    # -----------------------------
    # Fetch authoritative record
    # -----------------------------
    record = fetch_inform_record(instance_uuid, form_data["IP_Name"])

    if record is None:
        return JsonResponse({"success": False, "message": "InForm lookup failed"}, status=500)

    # -----------------------------
    # Save to local DB
    # -----------------------------
    b = _save_record_from_inform(record)

    # Update households
    changes = assign_households()

    return JsonResponse({
        "success": True,
        "changes": changes,
        "beneficiary": serialize_beneficiary(b),
    })


# -----------------------------------------------------------
# 🟡 UPDATE BENEFICIARY
# -----------------------------------------------------------
def _handle_update(payload):
    pk = payload.get("id")
    if not pk:
        return JsonResponse({"error": "Missing id for update"}, status=400)

    obj = get_object_or_404(Beneficiary.all_objects, pk=pk)

    id_number = safe_value(payload.get("ID_Number"))
    duplicates = Beneficiary.all_objects.filter(ID_Number=id_number).exclude(pk=pk)

    if duplicates.exists():
        return JsonResponse({
            "success": False,
            "duplicate": True,
            "message": f"Duplicate ID_Number {id_number}"
        }, status=409)

    old_instance_id = obj.InstanceID
    new_instance_id = f"uuid:{uuid.uuid4()}"

    # Update local fields
    _update_local_fields(obj, payload)

    obj.save()

    # Household update
    assign_households()

    # -------------------------
    # Prepare InForm submission
    # -------------------------
    form_data = _extract_local_fields(payload)
    form_data["meta_instance_id"] = new_instance_id
    form_data["meta_deprecated"] = old_instance_id

    result = submit_to_inform(form_data)

    if result["success"]:
        obj.InstanceID = new_instance_id
        obj.save()

    return JsonResponse({
        "success": True,
        "beneficiary": serialize_beneficiary(obj),
    })


# -----------------------------------------------------------
# 🔴 DELETE BENEFICIARY (Soft Delete)
# -----------------------------------------------------------
def _handle_delete(payload):
    pk = payload.get("id")
    if not pk:
        return JsonResponse({"error": "Missing id for delete"}, status=400)

    obj = get_object_or_404(Beneficiary.all_objects, pk=pk)

    new_instance_id = f"uuid:{uuid.uuid4()}"
    obj.Deleted = True
    obj.deleted_at = timezone.now()
    obj.deleted_by = payload.get("deleted_by")

    obj.save()

    # InForm delete payload
    form_data = _extract_local_fields(payload)
    form_data["Deleted"] = True
    form_data["deleted_at"] = obj.deleted_at.strftime("%Y-%m-%dT%H:%M:%S")
    form_data["meta_instance_id"] = new_instance_id
    form_data["meta_deprecated"] = obj.InstanceID

    result = submit_to_inform(form_data)

    if result["success"]:
        obj.InstanceID = new_instance_id
        obj.save()

    return JsonResponse({
        "success": True,
        "beneficiary": serialize_beneficiary(obj),
    })


# -----------------------------------------------------------
# 🟣 RESTORE BENEFICIARY
# -----------------------------------------------------------
def _handle_restore(payload):
    pk = payload.get("id")
    if not pk:
        return JsonResponse({"error": "Missing id for restore"}, status=400)

    obj = get_object_or_404(Beneficiary.deleted_objects, pk=pk)

    new_instance_id = f"uuid:{uuid.uuid4()}"
    obj.Deleted = False
    obj.undeleted_at = timezone.now()
    obj.undeleted_by = payload.get("undeleted_by")
    obj.save()

    # InForm restore payload
    form_data = _extract_local_fields(payload)
    form_data["Deleted"] = False
    form_data["undeleted_at"] = obj.undeleted_at.strftime("%Y-%m-%dT%H:%M:%S")
    form_data["meta_instance_id"] = new_instance_id
    form_data["meta_deprecated"] = obj.InstanceID

    result = submit_to_inform(form_data)

    if result["success"]:
        obj.InstanceID = new_instance_id
        obj.save()

    return JsonResponse({
        "success": True,
        "beneficiary": serialize_beneficiary(obj),
    })


# -----------------------------------------------------------
# 🔧 HELPERS — extract fields
# -----------------------------------------------------------
def _extract_local_fields(p):
    """Return only fields that belong to Beneficiary."""
    keys = [
        "IP_Name", "Sector", "Indicator", "Date", "Name", "ID_Number",
        "Parent_ID", "Spouse_ID", "Phone_Number", "Date_of_Birth",
        "Age", "Gender", "Governorate", "Municipality", "Neighborhood",
        "Site_Name", "Disability_Status",
    ]

    return {k: safe_value(p.get(k)) for k in keys}


def _update_local_fields(obj, p):
    """Assign incoming values to the Django object."""
    for k, v in _extract_local_fields(p).items():
        setattr(obj, k, v)


def _save_record_from_inform(record):
    """Record returned from InForm → save to Django."""
    obj = Beneficiary()

    for field, value in record.items():
        if hasattr(obj, field):
            setattr(obj, field, safe_value(value))

    obj.save()
    return obj
