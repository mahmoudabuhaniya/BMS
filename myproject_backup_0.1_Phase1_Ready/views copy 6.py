import time
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
from django.shortcuts import render, redirect
from django.contrib.auth import authenticate, login, logout
from django.contrib import messages
from django.contrib.auth.forms import AuthenticationForm
from django.contrib.auth.decorators import login_required
from django.contrib.auth.models import User
from django.contrib.auth.forms import PasswordChangeForm
from django.contrib.auth import update_session_auth_hash



def home(request):
    last_sync_record = Beneficiary.objects.order_by('-created_at').first()
    last_sync_time = localtime(last_sync_record.created_at).strftime("%Y-%m-%d %H:%M") if last_sync_record else "Never"
    return render(request, 'myproject/home.html', {'last_sync_time': last_sync_time})

def get_item(dictionary, key):
    if isinstance(dictionary, dict):
        return dictionary.get(key, "")
    return ""


progress_status = {"stage": "", "progress": 0}

def sync_data(request):
    if request.method != 'POST':
        global progress_status
        progress_status = {"stage": "Starting sync ...", "progress": 1}
        return JsonResponse({"status": "error", "message": "Invalid request method. Only POST allowed."})

    tokens = APIToken.objects.all()
    if not tokens.exists():
        progress_status = {"stage": "No API tokens available.", "progress": 0}
        return JsonResponse({"error": "No API tokens available."}, status=400)

    total_fetched = 0
    new_count = 0
    duplicate_count = 0
    invalid_date_count = 0

    try:
        for token in tokens:
            page = 1
            record = 0
            page_size = 10000  # max records per page
            while True:
                url = f"https://data.inform.unicef.org/api/v1/data/{token.form_id}.json?page={page}&page_size={page_size}"
                headers = {"Authorization": f"Token {token.token}", "Content-Type": "application/json"}
                response = requests.get(url, headers=headers)

                if response.status_code != 200:
                    break  # stop if request fails

                data = response.json()
                if not data:
                    break  # no more records

                prev_fetched = total_fetched
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

                    # Process the data...
                    rec_progress = int((prev_fetched + record / total_fetched) * 100) if prev_fetched else 0
                    #global progress_status
                    progress_status = {"stage": f"IP Name: {get_val('IP_Name')} (part {page}) - Processing record {record} of {total_fetched} ...", "progress": rec_progress}
                    record += 1
                    

                    InForm_ID = get_val("_id")
                    record_id = InForm_ID  # Use InForm ID as unique identifier
                    if Beneficiary.objects.filter(record_id=record_id).exists():
                        duplicate_count += 1
                        continue  # skip duplicates

                    IP_Name = get_val("IP_Name")
                    Sector = get_val("Sector")
                    Indicator = get_val("Indicator")
                    Name = get_val("Name")
                    ID_Number = get_val("ID_Number")
                    Phone_Number = get_val("Phone_Number")
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
                                return raw_date.strftime("%Y-%m-%d")
                            elif isinstance(raw_date, str):
                                raw_date = raw_date.strip()
                                if raw_date.lower() in ["", "null", "n/a", "none"]:
                                    return None
                                return raw_date  # already in YYYY-MM-DD
                            else:
                                return None
                        except Exception:
                            nonlocal invalid_date_count
                            invalid_date_count += 1
                            return None

                    PDate = parse_date(get_val("Date"))
                    PDate_of_Birth = parse_date(get_val("Date_of_Birth"))

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

                page += 1  # next page

        return JsonResponse({
            "status": "success",
            "new_count": new_count,
            "duplicate_count": duplicate_count,
            "invalid_date_count": invalid_date_count,
            "total_fetched": total_fetched,
            "message": "Sync completed successfully."
        })
        time.sleep(1)

    except Exception as e:
        return JsonResponse({"status": "error", "message": f"❌ Sync failed: {str(e)}"})

def get_progress(request):
    return JsonResponse(progress_status)

def inform_data_view(request):
    beneficiaries_list = Beneficiary.objects.all().order_by('-created_at')
    paginator = Paginator(beneficiaries_list, 18)  # Show 18 per page
    page_number = request.GET.get('page')
    submissions = paginator.get_page(page_number)

    return render(request, 'myproject/inform_data.html', {'submissions': submissions})

@login_required
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

@login_required
def delete_token(request, pk):
    token = get_object_or_404(APIToken, pk=pk)
    token.delete()
    messages.success(request, "API token deleted successfully.")
    return redirect('manage_tokens')  # Redirect back to the manage tokens page

def user_login(request):
    if request.method == 'POST':
        form = AuthenticationForm(request, data=request.POST)
        if form.is_valid():
            user = form.get_user()
            login(request, user)
            messages.success(request, "You have successfully logged in.")
            return redirect('home')  # Redirect to your desired page
        else:
            messages.error(request, "Invalid username or password.")
    else:
        form = AuthenticationForm()

    context = {
        'form': form,
    }
    return render(request, 'myproject/login.html', context)

def user_logout(request):
    logout(request)
    messages.success(request, "You have been logged out.")
    return redirect("home")  # Replace with your login URL name



def user_register(request):
    if request.method == "POST":
        username = request.POST.get("username")
        email = request.POST.get("email")
        first_name = request.POST.get("first_name")
        last_name = request.POST.get("last_name")
        password = request.POST.get("password")
        confirm_password = request.POST.get("confirm_password")

        if password == confirm_password:
            if User.objects.filter(username=username).exists():
                messages.error(request, "Username already exists.")
            elif User.objects.filter(email=email).exists():
                messages.error(request, "Email is already registered.")
            else:
                user = User.objects.create_user(username=username, email=email, first_name=first_name, last_name=last_name, password=password)
                user.is_active = True  # 🔑 make sure the account is active
                user.save()
                print(user.password)
                messages.success(request, "Account created successfully! Please log in.")
                return redirect('login')
        else:
            messages.error(request, "Passwords do not match.")
    return render(request, 'myproject/register.html')


@login_required
def profile(request):
    if request.method == "POST":
        user = request.user
        user.first_name = request.POST.get("first_name")
        user.last_name = request.POST.get("last_name")
        user.email = request.POST.get("email")
        user.save()
        messages.success(request, "User profile updated successfully!")
        return redirect("home")
    return render(request, "myproject/profile.html")

@login_required
def password_change(request):
    if request.method == "POST":
        form = PasswordChangeForm(request.user, request.POST)
        if form.is_valid():
            user = form.save()
            # Keep user logged in after password change
            update_session_auth_hash(request, user)
            messages.success(request, "✅ Your password was successfully updated!")
            return redirect("home")  # redirect to profile or dashboard
        else:
            messages.error(request, "❌ Please correct the errors below.")
    else:
        form = PasswordChangeForm(request.user)

    return render(request, "myproject/password_change.html", {"form": form})