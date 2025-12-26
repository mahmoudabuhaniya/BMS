import uuid, requests

def safe_value(v):
    return v if v is not None else ""

inform_api_url = "https://inform.unicef.org/unicefstateofpalestine/5371/api/v1/submissions"
APIToken = "ef5a72dad573916ed3a2289e51ca4f1b8ced5c88"

payload = {
    "id": "Beneficiary_Database_Form_Template_-_RRM",  # <-- use id_string, not title
    "submission": {
        "start": None,
        "end": None,
        "Name": "Ali",
        "ID_Number": "123456789",
        "Phone_Number": "0591234567",
        "Date_of_Birth": "2010-05-22",
        "Age": "14",
        "Gender": "Male",
        "Governorate": "Gaza",
        "Municipality": "Gaza City",
        "Neighborhood": "Shujaeya",
        "Site_Name": "Camp 4",
        "Disability_Status": "None",
        "Sector": "Education",
        "IP_Name": "UNICEF Partner",
        "Indicator": "RRM",
        "Date": "2025-10-17"
    }
}

headers = {
    "Authorization": f"Token {APIToken}",
    "Content-Type": "application/json"
}

response = requests.post(inform_api_url, headers=headers, json=payload)

print(response.status_code)
print(response.text)
if response.status_code == 201:
    print("✅ Submission successful")