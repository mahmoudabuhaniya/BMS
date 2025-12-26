# myproject/api/inform_api.py

import json
import uuid
import requests
from django.conf import settings

from myproject.views import safe_value, get_form_id_string


# --------------------------------------------------------------------
# 🔐 1. CONFIG
# --------------------------------------------------------------------
INFORM_API_URL = "https://data.inform.unicef.org/unicefstateofpalestine/submission"
FETCH_API_URL = "https://data.inform.unicef.org/api/v1/data"

# You can store these in Django settings later
DEFAULT_INFORM_TOKEN = "ef5a72dad573916ed3a2289e51ca4f1b8ced5c88"


# --------------------------------------------------------------------
# 🔧 2. SUBMIT RECORD TO INFORM (Create / Update / Delete / Restore)
# --------------------------------------------------------------------
def submit_to_inform(record, form_id, instance_id):
    """
    Sends one submission to InForm.
    Returns: (success_boolean, returned_inform_id_or_None)
    """

    instance_id = instance_id or f"uuid:{uuid.uuid4()}"
    

    payload = {
        "id": form_id,
        "submission": {
            # DATA FIELDS — all safe_value normalized
            "IP_Name": safe_value(record.get("IP_Name")),
            "Sector": safe_value(record.get("Sector")),
            "Indicator": safe_value(record.get("Indicator")),
            "Date": safe_value(record.get("Date")),
            "Name": safe_value(record.get("Name")),
            "ID_Number": safe_value(record.get("ID_Number")),
            "Parent_ID": safe_value(record.get("Parent_ID")),
            "Spouse_ID": safe_value(record.get("Spouse_ID")),
            "Phone_Number": safe_value(record.get("Phone_Number")),
            "Date_of_Birth": safe_value(record.get("Date_of_Birth")),
            "Age": safe_value(record.get("Age")),
            "Gender": safe_value(record.get("Gender")),
            "Governorate": safe_value(record.get("Governorate")),
            "Municipality": safe_value(record.get("Municipality")),
            "Neighborhood": safe_value(record.get("Neighborhood")),
            "Site_Name": safe_value(record.get("Site_Name")),
            "Disability_Status": safe_value(record.get("Disability_Status")),
            "created_by": safe_value(record.get("created_by") or "mobile"),
            # SOFT DELETE FIELDS
            "Deleted": record.get("Deleted"),
            "deleted_at": safe_value(record.get("deleted_at")),
            "undeleted_at": safe_value(record.get("undeleted_at")),
            

            # META
            "meta": {
                "instanceID": instance_id,
                "deprecatedID": None,
            },
        },
    }

    headers = {
        "Authorization": f"Token {DEFAULT_INFORM_TOKEN}",
        "Content-Type": "application/json",
    }

    try:
        response = requests.post(
            INFORM_API_URL,
            headers=headers,
            data=json.dumps(payload, default=str),
            timeout=20,
        )

        if response.status_code not in (200, 201):
            print(f"❌ InForm API error {response.status_code}: {response.text}")
            return False, None

        # Success — backend does not return inform id directly
        return True, None

    except Exception as e:
        print(f"❌ InForm network exception: {e}")
        return False, None


# --------------------------------------------------------------------
# 🔍 3. FETCH RECORD BACK FROM INFORM USING _uuid
# --------------------------------------------------------------------
def fetch_inform_record(form_id, uuid_value):
    """
    After submit, fetch record from InForm using _uuid.
    Returns: dict | None
    """

    try:
        query = json.dumps({"_uuid": str(uuid_value)})
        url = f"{FETCH_API_URL}/{form_id}.json?query={query}"

        headers = {
            "Authorization": f"Token {DEFAULT_INFORM_TOKEN}",
            "Content-Type": "application/json",
        }

        response = requests.get(url, headers=headers, timeout=20)
        response.raise_for_status()

        data = response.json()

        # Payload may be {"data": [...]} or just [...]
        if isinstance(data, dict) and "data" in data:
            data = data["data"]

        if not data:
            print(f"⚠️ No InForm record found for UUID {uuid_value}")
            return None

        record = data[0] if isinstance(data, list) else data

        # Normalize list/tuple values
        normalized = {}

        for key, val in record.items():
            if isinstance(val, (tuple, list)):
                normalized[key] = val[0] if val else None
            else:
                normalized[key] = safe_value(val)

        return normalized

    except Exception as e:
        print(f"❌ Error fetching InForm record: {e}")
        return None
