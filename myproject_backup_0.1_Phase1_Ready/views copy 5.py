from django.shortcuts import get_object_or_404, render, redirect
from django.contrib import messages
import requests
from .models import Beneficiary, APIToken
from datetime import datetime
from django.core.paginator import Paginator
from django.http import JsonResponse
from django.utils.timezone import localtime
from .forms import APITokenForm
from datetime import datetime, date



def home(request):
    last_sync_record = Beneficiary.objects.order_by('-created_at').first()
    last_sync_time = localtime(last_sync_record.created_at).strftime("%Y-%m-%d %H:%M") if last_sync_record else "Never"
    return render(request, 'myproject/home.html', {'last_sync_time': last_sync_time})

def get_item(dictionary, key):
    if isinstance(dictionary, dict):
        return dictionary.get(key, "")
    return ""


def sync_inform_data(request):
    if request.method != 'POST':
        return JsonResponse({"status": "error", "message": "Invalid request method. Only POST allowed."})

    tokens = APIToken.objects.all()
    if not tokens.exists():
        return JsonResponse({"error": "No API tokens available."}, status=400)

    total_fetched = 0
    new_count = 0
    duplicate_count = 0
    invalid_date_count = 0

    # Get last sync time based on created_at
    last_sync_record = Beneficiary.objects.order_by('-created_at').first()
    last_sync_time = last_sync_record.created_at if last_sync_record else None

    try:
        for token in tokens:
            url = f"https://data.inform.unicef.org/api/v1/data/{token.form_id}.json"
            headers = {"Authorization": f"Token {token.token}", "Content-Type": "application/json"}

            response = requests.get(url, headers=headers)
            if response.status_code != 200:
                continue  # skip this token

            data = response.json()
            total_fetched += len(data)

            for item in data:
                # --- Extract values safely ---
                def get_val(key):
                    val = item.get(key)
                    if isinstance(val, (tuple, list)):
                        val = val[0] if val else None
                    if isinstance(val, str):
                        val = val.strip()
                        if val.lower() in ["", "null", "n/a", "none"]:
                            return None
                    return val

                InForm_ID = get_val("_id")
                record_id = InForm_ID  # Use InForm ID as unique identifier
                if Beneficiary.objects.filter(record_id=record_id).exists():
                    duplicate_count += 1
                    continue  # skip duplicates

                IP_Name = get_val("IP_Name")
                Sector = get_val("Sector")
                Indicator = get_val("Indicator")
                Date = get_val("Date")
                Name = get_val("Name")
                ID_Number = get_val("ID_Number")
                Phone_Number = get_val("Phone_Number")
                Date_of_Birth = get_val("Date_of_Birth")
                Age = get_val("Age")
                Gender = get_val("Gender")
                Governorate = get_val("Governorate")
                Municipality = get_val("Municipality")
                Neighborhood = get_val("Neighborhood")
                Site_Name = get_val("Site_Name")
                Disability_Status = get_val("Disability_Status")

                # --- Dates ---
                def parse_date(raw_date):
                    if raw_date is None:
                        return None
                    try:
                        if isinstance(raw_date, date):
                            # Already a date object
                            return raw_date.strftime("%Y-%m-%d")
                        elif isinstance(raw_date, str):
                            raw_date = raw_date.strip()
                            if raw_date.lower() in ["", "null", "n/a", "none"]:
                                return None
                            # Already in YYYY-MM-DD format, just return
                            return raw_date
                        else:
                            return None
                    except Exception:
                        nonlocal invalid_date_count
                        invalid_date_count += 1
                        return None

                PDate = parse_date(get_val("Date"))
                PDate_of_Birth = parse_date(get_val("Date_of_Birth"))

                # --- Only import if after last sync (optional: if timestamp available in data) ---
                # Here we assume all new records should be imported if not duplicate

                # --- Create Beneficiary ---
                Beneficiary.objects.create(
                    record_id=record_id,
                    InForm_ID=InForm_ID,
                    IP_Name=IP_Name,
                    Sector=Sector,
                    Indicator=Indicator,
                    Date=PDate,
                    Name=Name,
                    ID_Number=ID_Number,
                    Phone_Number=Phone_Number,
                    Date_of_Birth=PDate_of_Birth,
                    Age=Age,
                    Gender=Gender,
                    Governorate=Governorate,
                    Municipality=Municipality,
                    Neighborhood=Neighborhood,
                    Site_Name=Site_Name,
                    Disability_Status=Disability_Status
                )
                new_count += 1

        return JsonResponse({
            "status": "success",
            "message": f"✅ Sync completed: {new_count} new added, {duplicate_count} skipped, {invalid_date_count} invalid dates, total fetched: {total_fetched}."
        })

    except Exception as e:
        return JsonResponse({"status": "error", "message": f"❌ Sync failed: {str(e)}"})


def inform_data_view(request):
    beneficiaries_list = Beneficiary.objects.all().order_by('-created_at')
    paginator = Paginator(beneficiaries_list, 18)  # Show 18 per page
    page_number = request.GET.get('page')
    submissions = paginator.get_page(page_number)

    return render(request, 'myproject/inform_data.html', {'submissions': submissions})

#@login_required
def manage_tokens(request):
    if request.method == 'POST':
        form = APITokenForm(request.POST)
        if form.is_valid():
            form.save()
            messages.success(request, "✅ Token saved successfully.")
            return redirect('manage_tokens')
        else:
            messages.error(request, "❌ Please correct the errors below.")
    else:
        form = APITokenForm()

    tokens = APIToken.objects.all().order_by('-id')  # Optional: newest on top
    return render(request, 'myproject/manage_tokens.html', {
        'form': form,
        'tokens': tokens
    })

def delete_token(request, pk):
    token = get_object_or_404(APIToken, pk=pk)
    token.delete()
    messages.success(request, "API token deleted successfully.")
    return redirect('manage_tokens')  # Redirect back to the manage tokens page
