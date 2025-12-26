# myproject/mobile_api/mobile_serializers.py

from datetime import date, datetime
from myproject.models import Beneficiary


# -----------------------------------------------------------
# 🧹 CLEAN/FORMAT ANY VALUE FOR MOBILE
# -----------------------------------------------------------
def fmt(value):
    """Convert Django values → safe JSON values."""
    if value is None:
        return None

    # Dates → YYYY-MM-DD
    if isinstance(value, date) and not isinstance(value, datetime):
        return value.strftime("%Y-%m-%d")

    # DateTimes → ISO format
    if isinstance(value, datetime):
        return value.strftime("%Y-%m-%dT%H:%M:%S")

    # Trim strings & clean "null"/""
    if isinstance(value, str):
        v = value.strip()
        return v if v.lower() not in ("", "null", "none", "n/a") else None

    return value


# -----------------------------------------------------------
# 🧩 SERIALIZE ONE BENEFICIARY RECORD → MOBILE JSON
# -----------------------------------------------------------
def serialize_beneficiary(obj: Beneficiary):
    """Convert a Beneficiary model instance into JSON for mobile."""

    return {
        "id": obj.id,
        "record_id": fmt(obj.record_id),
        "InForm_ID": fmt(obj.InForm_ID),
        "InstanceID": fmt(obj.InstanceID),

        "IP_Name": fmt(obj.IP_Name),
        "Sector": fmt(obj.Sector),
        "Indicator": fmt(obj.Indicator),
        "Date": fmt(obj.Date),
        "Name": fmt(obj.Name),
        "ID_Number": fmt(obj.ID_Number),
        "Parent_ID": fmt(obj.Parent_ID),
        "Spouse_ID": fmt(obj.Spouse_ID),
        "Phone_Number": fmt(obj.Phone_Number),
        "Date_of_Birth": fmt(obj.Date_of_Birth),
        "Age": fmt(obj.Age),
        "Gender": fmt(obj.Gender),
        "Governorate": fmt(obj.Governorate),
        "Municipality": fmt(obj.Municipality),
        "Neighborhood": fmt(obj.Neighborhood),
        "Site_Name": fmt(obj.Site_Name),
        "Disability_Status": fmt(obj.Disability_Status),

        "Submission_Time": fmt(obj.Submission_Time),
        "created_at": fmt(obj.created_at),
        "updated_at": fmt(obj.updated_at),
        "updated_by": fmt(obj.updated_by),
        "created_by": fmt(obj.created_by),

        # 🔥 SOFT DELETE FIELDS
        "Deleted": obj.Deleted is True,
        "deleted_at": fmt(obj.deleted_at),
        "deleted_by": fmt(obj.deleted_by),
        "undeleted_at": fmt(obj.undeleted_at),
        "undeleted_by": fmt(obj.undeleted_by),

        # Household
        "Household_ID": fmt(obj.Household_ID),

        # Sync flag
        "synced": fmt(obj.synced),
    }


# -----------------------------------------------------------
# 📦 SERIALIZE PAGINATED LISTS
# -----------------------------------------------------------
def serialize_beneficiary_list(qs):
    """Return list of serialized beneficiaries."""
    return [serialize_beneficiary(obj) for obj in qs]
