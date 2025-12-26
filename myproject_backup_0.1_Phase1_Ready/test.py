import requests

token = "ef5a72dad573916ed3a2289e51ca4f1b8ced5c88"
#url = "https://data.inform.unicef.org/api/v1/forms/submissions"
url = "https://data.inform.unicef.org/projects/5371/submission"
headers = {
    "Authorization": f"Token {token}",
    "Content-Type": "application/json"
}




payload = {
    "id": 8927,  # or your id_string
    "submission": {
        "Name": "Test User",
        "Governorate": "Hebron",
    }
}


r = requests.post(url, headers=headers, json=payload)
print("Status Code:", r.status_code)
print("Response:", r.text)
