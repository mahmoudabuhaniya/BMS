# myproject/api/mobile_orchestration.py

import uuid
import json
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.utils import timezone
from django.shortcuts import get_object_or_404

from myproject.models import Beneficiary
from myproject.utils import safe_value, assign_households, get_form_id_string
from myproject.inform_api import submit_to_inform, fetch_inform_record


# -------------------------------------------------------------------
# 📌 HELPER — Standard Response Format (Option C)
# -------------------------------------------------------------------
def response_success(message, data=None):
    return JsonResponse({
        "success": True,
        "message": message,
        "data": data
    }, status=200)


def response_error(message, code=400):
    return JsonResponse({
        "success": False,
        "message": message
    }, status=code)


# -------------------------------------------------------------------
# 📌 CREATE BENEFICIARY
# -------------------------------------------------------------------
@csrf_exempt
def mobile_create(request):
    if request.method != "POST":
        return response_error("Invalid request method", 405)

    try:
        payload = json.loads(request.body)
    except:
        return response_error("Invalid JSON payload")

    # 🔹 Duplicate check (same as web)
    id_number = payload.get("ID_Number")
    if id_number:
        if Beneficiary.all_objects.filter(ID_Number=id_number).exists():
            return response_error(f"⚠️ Duplicate beneficiaries found with ID {id_number}")

    # 🔹 Prepare Django model object
    new_uuid = uuid.uuid4()
    instance_id = f"uuid:{new_uuid}"

    # Convert payload to model fields
    record = Beneficiary(
        record_id=None,
        InForm_ID=None,
        InstanceID=instance_id,
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
        created_by=payload.get("created_by", "mobile"),
        Submission_Time=timezone.now(),
        Deleted=False,
        synced="no",
    )

    # ------------------------------------------------------------
    # 🔹 STEP 1: Push to InForm API
    # ------------------------------------------------------------
    form_id = get_form_id_string(record.IP_Name)
    submit_ok, inform_id = submit_to_inform(record, form_id)

    if not submit_ok:
        return response_error("❌ Failed to submit to InForm API")

    # ------------------------------------------------------------
    # 🔹 STEP 2: Get returned record from InForm
    # ------------------------------------------------------------
    inform_record = fetch_inform_record(form_id, new_uuid)
    if not inform_record:
        return response_error("❌ Submitted to InForm, but no record was returned")

    # Sync InForm → Django fields
    record.InForm_ID = inform_record.get("_id")
    record.record_id = inform_record.get("_id")
    record.save()

    # ------------------------------------------------------------
    # 🔹 STEP 3: Update households
    # ------------------------------------------------------------
    changes = assign_households()

    # ------------------------------------------------------------
    # 🔹 Return result
    # ------------------------------------------------------------
    return response_success(
        f"✅ Beneficiary added & synced. Household updated for {changes} records.",
        data={"id": record.id, "InForm_ID": record.InForm_ID}
    )


# -------------------------------------------------------------------
# 📌 UPDATE BENEFICIARY
# -------------------------------------------------------------------
@csrf_exempt
def mobile_update(request, pk):
    if request.method != "POST":
        return response_error("Invalid method", 405)

    record = get_object_or_404(Beneficiary.all_objects, pk=pk)

    try:
        payload = json.loads(request.body)
    except:
        return response_error("Invalid JSON")

    # 🔹 Duplicate check
    id_number = payload.get("ID_Number")
    if id_number:
        dup = Beneficiary.all_objects.filter(ID_Number=id_number).exclude(pk=pk)
        if dup.exists():
            return response_error(f"⚠️ Duplicate beneficiaries found with ID {id_number}")

    # 🔹 Update fields (same logic as web)
    old_instance = record.InstanceID
    new_instance = f"uuid:{uuid.uuid4()}"

    for field in [
        "IP_Name", "Sector", "Indicator", "Date", "Name", "ID_Number",
        "Parent_ID", "Spouse_ID", "Phone_Number", "Date_of_Birth",
        "Age", "Gender", "Governorate", "Municipality",
        "Neighborhood", "Site_Name", "Disability_Status"
    ]:
        setattr(record, field, safe_value(payload.get(field)))

    record.InstanceID = new_instance
    record.save()

    # 🔹 Push updated version to InForm
    form_id = get_form_id_string(record.IP_Name)
    ok, _ = submit_to_inform(record, form_id, deprecated_id=old_instance)

    if not ok:
        return response_error("⚠️ Local update saved but InForm sync failed")

    # 🔹 Household update
    changes = assign_households()

    return response_success(
        f"✅ Record updated & synced. Household updated for {changes} records."
    )


# -------------------------------------------------------------------
# 📌 SOFT DELETE
# -------------------------------------------------------------------
@csrf_exempt
def mobile_delete(request, pk):
    if request.method != "POST":
        return response_error("Invalid method", 405)

    record = get_object_or_404(Beneficiary.all_objects, pk=pk)

    record.Deleted = True
    record.deleted_at = timezone.now()
    record.deleted_by = request.POST.get("deleted_by", "mobile")
    old_instance = record.InstanceID
    new_instance = f"uuid:{uuid.uuid4()}"
    record.InstanceID = new_instance
    record.save()

    # 🔹 Push deletion to InForm
    form_id = get_form_id_string(record.IP_Name)
    ok, _ = submit_to_inform(record, form_id, deprecated_id=old_instance)

    if not ok:
        return response_error("⚠️ Deleted locally but failed to sync with InForm")

    return response_success("🗑️ Beneficiary deleted & synced successfully")


# -------------------------------------------------------------------
# 📌 RESTORE
# -------------------------------------------------------------------
@csrf_exempt
def mobile_restore(request, pk):
    if request.method != "POST":
        return response_error("Invalid method", 405)

    record = get_object_or_404(Beneficiary.deleted_objects, pk=pk)

    record.Deleted = False
    record.undeleted_at = timezone.now()
    record.undeleted_by = request.POST.get("undeleted_by", "mobile")
    old_instance = record.InstanceID
    new_instance = f"uuid:{uuid.uuid4()}"
    record.InstanceID = new_instance
    record.save()

    form_id = get_form_id_string(record.IP_Name)
    ok, _ = submit_to_inform(record, form_id, deprecated_id=old_instance)

    if not ok:
        return response_error("⚠️ Restored locally but failed to sync with InForm")

    return response_success("♻️ Beneficiary restored & synced successfully")


# -------------------------------------------------------------------
# 📌 PAGINATED SYNC (FIRST TIME / INCREMENTAL)
# -------------------------------------------------------------------
@csrf_exempt
def mobile_sync(request):
    """
    Params:
        updated_after: ISO datetime OR empty for full sync
        page: integer
        page_size: integer
    """
    if request.method != "GET":
        return response_error("Invalid method", 405)

    updated_after = request.GET.get("updated_after")
    page = int(request.GET.get("page", 1))
    size = int(request.GET.get("page_size", 1000))

    qs = Beneficiary.all_objects.all().order_by("updated_at")

    if updated_after:
        qs = qs.filter(updated_at__gt=updated_after)

    total = qs.count()
    start = (page - 1) * size
    end = start + size

    data = list(qs[start:end].values())

    return JsonResponse({
        "success": True,
        "total": total,
        "page": page,
        "page_size": size,
        "results": data
    })
