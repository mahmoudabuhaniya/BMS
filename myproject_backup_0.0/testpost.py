import requests
import uuid
import datetime

url = "https://data.inform.unicef.org/api/v1/submissions"
username = "mabuhaniya"
password = "CandyCrush$$8"



# The id_string of your XLSForm (check in ONA form settings / API)
form_id_string = "Beneficiary_Database_Form_Template_-_We_World"

# Construct submission data
submission_data = {
    "start": datetime.datetime.now().isoformat(),
    "end": datetime.datetime.now().isoformat(),
    "IP_Name": "WeWorld",
    "Sector": "Health",
    "Indicator": "Beneficiary Registered",
    "Date": "2025-09-23",
    "Name": "John Doe",
    "ID_Number": "123456789",
    "Phone_Number": "0591234567",
    "Date_of_Birth": "1990-01-01",
    "Age": "35",
    "Gender": "male",  # must match choice values in XLSForm
    "Governorate": "Hebron",
    "Municipality": "Hebron City",
    "Neighborhood": "Old Town",
    "Site_Name": "Clinic A",
    "Disability_Status": "no",
    "meta": {
        "instanceID": f"uuid:{uuid.uuid4()}"
    }
}

payload = {
    "id": form_id_string,
    "submission": submission_data
}

headers = {"Content-Type": "application/json"}

response = requests.post(
    url,
    json=payload,
    auth=(username, password),
    headers=headers
)

print("Status:", response.status_code)
print("Response:", response.text)
