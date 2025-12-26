import requests
from django.contrib import messages

INFORM_API_BASE_URL = f"https://data.inform.unicef.org/api/v1/data/"  # Base URL
#INFORM_API_TOKEN = token  # Replace with your real token



def get_form_submissions(form_id,token):
    url = f"{INFORM_API_BASE_URL}/{form_id}.json"
    HEADERS = {
    "Authorization": f"Token {token}",
    "Content-Type": "application/json"
    }
    response = requests.get(url, headers=HEADERS)

    if response.status_code == 200:
        data = response.json()
        # If API returns {"data": [...]}, extract it
        if isinstance(data, dict) and "data" in data:
            return data["data"]
        return data  # fallback if it's already a list
    else:
        raise Exception(f"Failed to fetch data: {response.status_code} - {response.text}")
