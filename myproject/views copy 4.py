from django.shortcuts import get_object_or_404, render, redirect
from django.contrib import messages
import requests
from .models import Beneficiary, APIToken
from datetime import datetime
from django.core.paginator import Paginator
from django.http import JsonResponse
from django.utils.timezone import localtime
from .forms import APITokenForm
from datetime import date



def home(request):
    last_sync_record = Beneficiary.objects.order_by('-created_at').first()
    last_sync_time = localtime(last_sync_record.created_at).strftime("%Y-%m-%d %H:%M") if last_sync_record else "Never"
    return render(request, 'myproject/home.html', {'last_sync_time': last_sync_time})

def get_item(dictionary, key):
    if isinstance(dictionary, dict):
        return dictionary.get(key, "")
    return ""

def sync_inform_data(request):
    if request.method == 'POST':
        global progress_status
        progress_status = {"stage": "Starting sync ...", "progress": 1}

        INFORM_API_BASE_URL = "https://data.inform.unicef.org/api/v1/data"
        tokens = APIToken.objects.all()

        if not tokens.exists():
            progress_status = {"stage": "No API tokens available.", "progress": 0}
            return JsonResponse({"error": "No API tokens available."}, status=400)

        try:
            total_fetched = 0
            new_count = 0
            duplicate_count = 0
            invalid_date_count = 0

            for token in tokens:
                url = f"{INFORM_API_BASE_URL}/{token.form_id}.json"
                HEADERS = {
                    "Authorization": f"Token {token.token}",
                    "Content-Type": "application/json"
                }

                response = requests.get(url, headers=HEADERS)
                if response.status_code != 200:
                    continue  # Skip to next token

                data = response.json()
                beneficiaries = data

                total_fetched += len(beneficiaries)

                for item in beneficiaries:
                    #record_id=item.get("record_id"),
                    InForm_ID=item.get("_id"),
                    IP_Name=item.get("IP_Name"),
                    Sector=item.get("Sector"),
                    Indicator=item.get("Indicator"),
                    raw_date1=item.get("Date"),
                    Name=item.get("Name"),
                    ID_Number=item.get("ID_Number"),
                    Phone_Number=item.get("Phone_Number"),
                    raw_date2=item.get("Date_of_Birth"),
                    Age=item.get("Age"),
                    Gender=item.get("Gender"),
                    Governorate=item.get("Governorate"),
                    Municipality=item.get("Municipality"),
                    Neighborhood=item.get("Neighborhood"),
                    Site_Name=item.get("Site_Name"),
                    Disability_Status=item.get("Disability_Status"),
                    
                    parsed_date1 = None
                    parsed_date2 = None

                    # ✅ Validate date
                    # --- raw_date1 ---
                    if isinstance(raw_date1, tuple):
                        raw_date1 = raw_date1[0]

                    if raw_date1 and str(raw_date1).strip().lower() not in ["", "null", "n/a", "none"]:
                        try:
                            if isinstance(raw_date1, date):
                                # Already a date object → use as is
                                parsed_date1 = raw_date1.strftime("%Y-%m-%d")
                            else:
                                # Parse string in MM-DD-YYYY format from InForm
                                parsed = datetime.strptime(str(raw_date1), "%m-%d-%Y")
                                parsed_date1 = parsed.strftime("%Y-%m-%d")  # store in SQLite as YYYY-MM-DD
                        except ValueError:
                            invalid_date_count += 1
                            parsed_date1 = None
                    else:
                        invalid_date_count += 1
                        parsed_date1 = None

                    # --- raw_date2 ---
                    if isinstance(raw_date2, tuple):
                        raw_date2 = raw_date2[0]

                    if raw_date2 and str(raw_date2).strip().lower() not in ["", "null", "n/a", "none"]:
                        try:
                            if isinstance(raw_date2, date):
                                parsed_date2 = raw_date2.strftime("%Y-%m-%d")
                            else:
                                parsed = datetime.strptime(str(raw_date2), "%m-%d-%Y")
                                parsed_date2 = parsed.strftime("%Y-%m-%d")
                        except ValueError:
                            invalid_date_count += 1
                            parsed_date2 = None
                    else:
                        invalid_date_count += 1
                        parsed_date2 = None


                    # ✅ Check for duplicates
                    if Beneficiary.objects.filter(record_id=record_id).exists():
                        duplicate_count += 1
                    else:
                        Beneficiary.objects.create(
                            #record_id=record_id,
                            InForm_ID=InForm_ID,
                            IP_Name=IP_Name,
                            Sector=Sector,
                            Indicator=Indicator,
                            Date=parsed_date1,
                            Name=Name,
                            ID_Number=ID_Number,
                            Phone_Number=Phone_Number,
                            Date_of_Birth=parsed_date2,
                            Age=Age,
                            Gender=Gender,
                            Governorate=Governorate,
                            Municipality=Municipality,
                            Neighborhood=Neighborhood,
                            Site_Name=Site_Name,
                            Disability_Status=Disability_Status
                        )
                        new_count += 1

            # ✅ After all tokens are processed
            
            return JsonResponse({
                "status": "success",
                "message": f"✅ Sync completed: {new_count} new added, {duplicate_count} skipped, {invalid_date_count} invalid dates, total fetched: {total_fetched}."
                
            })

        except Exception as e:
            return JsonResponse({"status": "error", "message": f"❌ Sync failed: {str(e)}"})

    return JsonResponse({"status": "error", "message": "Invalid request method. Only POST allowed."})


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
