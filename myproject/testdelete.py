import requests
import uuid
from datetime import datetime, timezone

# -------------------------------
# CONFIG
# -------------------------------
form_id = "9288"
api_token = "ef5a72dad573916ed3a2289e51ca4f1b8ced5c88"

base_url = "https://data.inform.unicef.org/api/v1"
headers = {"Authorization": f"Token {api_token}", "Content-Type": "application/json"}
record_no = "234"  # Replace with the actual record number to delete


# -------------------------------
# STEP 5: Submit payload
# -------------------------------
data_url = f"{base_url}/data/{form_id}/10582163"
response = requests.delete(data_url, headers=headers)

if response.status_code == 204:
    print(f"✅ Record {record_no} successfully deleted!")
else:
    print(f"❌ Failed to delete record {record_no}. Status: {response.status_code}")
    print(response.text)