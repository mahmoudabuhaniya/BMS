import requests

    # Replace with your actual values
    token = "ef5a72dad573916ed3a2289e51ca4f1b8ced5c88"
    form_id = "9288"
    page = 1
    page_size = 100

    url = f"https://data.inform.unicef.org/api/v1/data/{form_id}.json?page={page}&page_size={page_size}"
    headers = {
        "Authorization": f"Token {token}",
        "Content-Type": "application/json"
    }

    response = requests.get(url, headers=headers)

    if response.status_code == 200:
        data = response.json()
        print(f"✅ Retrieved {len(data)} records")
        for record in data[:5]:  # print first 5 as sample
            print(record)
    else:
        print(f"❌ Failed. Status: {response.status_code}")
        print("Response:", response.text)
