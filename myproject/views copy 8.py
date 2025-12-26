import time
from django.shortcuts import get_object_or_404, render, redirect
from django.contrib import messages
from django.conf import settings
import requests
from .models import Beneficiary, APIToken
from datetime import datetime
from django.core.paginator import Paginator
from django.http import JsonResponse, HttpResponseForbidden, Http404
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
from django.contrib.auth.views import PasswordChangeView
from django.urls import reverse_lazy, reverse
from .forms import StyledPasswordChangeForm
import json
import logging
from django.db.models import Count, Q
from django.views.decorators.http import require_POST
from django.views.decorators.csrf import csrf_exempt  # only if using non-ajax or external POSTs — prefer csrf
from django.db.models import Count
from django.db.models.functions import TruncMonth
# wherever you create beneficiary from get_val(...)
from .households import assign_households

@login_required
def home(request):
    # Gender distribution
    gender_data = Beneficiary.objects.values('Gender').annotate(total=Count('id'))
    gender_labels = [g['Gender'] or 'Unknown' for g in gender_data]
    gender_values = [g['total'] for g in gender_data]

    # Age groups (example buckets)
    age_buckets = {
        '0-17': Beneficiary.objects.filter(Age__lte=17).count(),
        '18-35': Beneficiary.objects.filter(Age__gte=18, Age__lte=35).count(),
        '36-60': Beneficiary.objects.filter(Age__gte=36, Age__lte=60).count(),
        '60+': Beneficiary.objects.filter(Age__gte=61).count(),
    }

    # Sector
    sector_data = Beneficiary.objects.values('IP_Name').annotate(total=Count('id'))
    sector_labels = [s['IP_Name'] or 'Unknown' for s in sector_data]
    sector_values = [s['total'] for s in sector_data]

    # Submissions over time (monthly)
    submissions = Beneficiary.objects.annotate(month=TruncMonth('Date')) \
                                     .values('month') \
                                     .annotate(total=Count('id')) \
                                     .order_by('month')
    submission_labels = [s['month'].strftime("%b %Y") for s in submissions if s['month']]
    submission_values = [s['total'] for s in submissions]

    # Governorates
    gov_data = Beneficiary.objects.values('Governorate').annotate(total=Count('id'))
    gov_labels = [g['Governorate'] or 'Unknown' for g in gov_data]
    gov_values = [g['total'] for g in gov_data]

    last_sync_record = Beneficiary.objects.order_by('-created_at').first()

    context = {
        "gender_labels": gender_labels,
        "gender_data": gender_values,
        "age_labels": list(age_buckets.keys()),
        "age_data": list(age_buckets.values()),
        "sector_labels": sector_labels,
        "sector_data": sector_values,
        "submission_labels": submission_labels,
        "submission_data": submission_values,
        "gov_labels": gov_labels,
        "gov_data": gov_values,
        
        "last_sync_record": Beneficiary.objects.order_by('-created_at').first(),
        "last_sync_time" : localtime(last_sync_record.created_at).strftime("%Y-%m-%d %H:%M") if last_sync_record else "Never",
    
    }
    return render(request, "myproject/home.html", context)

     
    
    return render(request, 'myproject/home.html', {'last_sync_time': last_sync_time})


def get_item(dictionary, key):
    if isinstance(dictionary, dict):
        return dictionary.get(key, "")
    return ""


import threading, time

progress_status = {"stage": "Not started", "progress": 0}

@login_required
def sync_data(request):
    global progress_status

    if request.method != 'POST':
        return JsonResponse({"status": "error", "message": "Invalid request method. Only POST allowed."})

    # Reset before new run
    progress_status = {"stage": "Starting sync ...", "progress": 1}

    def run_sync():
        global progress_status
        tokens = APIToken.objects.all()
        if not tokens.exists():
            progress_status = {"stage": "No API tokens available.", "progress": 0}
            return

        total_fetched = 0
        new_count = 0
        duplicate_count = 0
        invalid_date_count = 0

        try:
            for token in tokens:
                page = 1
                record = 0
                page_size = 10000
                while True:
                    url = f"https://data.inform.unicef.org/api/v1/data/{token.form_id}.json?page={page}&page_size={page_size}"
                    headers = {"Authorization": f"Token {token.token}", "Content-Type": "application/json"}
                    response = requests.get(url, headers=headers)

                    if response.status_code != 200:
                        break

                    data = response.json()
                    if not data:
                        break

                    prev_fetched = total_fetched
                    total_fetched += len(data)

                    for idx, item in enumerate(data, start=1):

                        def get_val(key):
                            val = item.get(key)
                            if isinstance(val, (tuple, list)):
                                val = val[0] if val else None
                            if isinstance(val, str):
                                val = val.strip()
                                if val.lower() in ["", "null", "n/a", "none"]:
                                    return None
                            return val

                        # update progress
                        percent = int((prev_fetched + idx) / (total_fetched + 1) * 100)
                        progress_status = {
                            "stage": f"IP Name: {get_val('IP_Name')} (part {page}) - Record {idx}/{len(data)}",
                            "progress": percent,
                            "new_count": new_count,
                            "duplicate_count": duplicate_count,
                            "invalid_date_count": invalid_date_count,
                            "total_fetched": total_fetched,
                            "completed": False,
                        }

                        InForm_ID = get_val("_id")
                        if Beneficiary.all_objects.filter(record_id=InForm_ID).exists():
                            duplicate_count += 1
                            continue

                        # save record
                        Beneficiary.all_objects.create(
                            record_id=InForm_ID,
                            InForm_ID=InForm_ID,
                            InstanceID=f"uuid:{get_val("_uuid")}",
                            IP_Name=get_val("IP_Name"),
                            Sector=get_val("Sector"),
                            Indicator=get_val("Indicator"),
                            Date=get_val("Date"),
                            Name=get_val("Name"),
                            ID_Number=get_val("ID_Number"),
                            Parent_ID=get_val("Parent_ID"),
                            Spouse_ID=get_val("Spouse_ID"),
                            Phone_Number=get_val("Phone_Number"),
                            Date_of_Birth=get_val("Date_of_Birth"),
                            Age=get_val("Age"),
                            Gender=get_val("Gender"),
                            Governorate=get_val("Governorate"),
                            Municipality=get_val("Municipality"),
                            Neighborhood=get_val("Neighborhood"),
                            Site_Name=get_val("Site_Name"),
                            Disability_Status=get_val("Disability_Status"),
                            Submission_Time = get_val("_submission_time"),
                            Deleted=get_val("Deleted"),
                        )
                        
                        new_count += 1

                    page += 1

            progress_status = {
                "stage": "✅ Sync completed",
                "progress": 100,
                "new_count": new_count,
                "duplicate_count": duplicate_count,
                "invalid_date_count": invalid_date_count,
                "total_fetched": total_fetched,
                "completed": True,
            }

        except Exception as e:
            progress_status = {
                "stage": f"❌ Error: {str(e)}",
                "progress": 100,
                "completed": True,
            }

    # Run the sync in a background thread
    thread = threading.Thread(target=run_sync)
    thread.start()

    return JsonResponse({"status": "started"})

    changes = assign_households()
    messages.success(request, f"Household assignment updated for {changes} records.")

    


def get_progress(request):
    global progress_status
    return JsonResponse(progress_status)



def inform_data_view(request):
    submissions = Beneficiary.objects.all()

    # --- Sorting ---
    sort_field = request.GET.get('sort', '-created_at')  # default sort
    # Ensure the sort field is valid
    valid_fields = [f.name for f in Beneficiary._meta.fields]
    if sort_field.lstrip('-') in valid_fields:
        submissions = submissions.order_by(sort_field)
    else:
        submissions = submissions.order_by('-created_at')

    # --- Filtering ---
    filter_fields = ['IP_Name','Sector','Indicator','Date','Name','ID_Number','Parent_ID','Spouse_ID','Phone_Number',
                     'Date_of_Birth','Age','Gender','Governorate','Household_ID']
    for field in filter_fields:
        value = request.GET.get(field)
        if value:
            submissions = submissions.filter(**{f"{field}__icontains": value})

    cnt = Beneficiary.objects.count()  # total in DB

    # --- Pagination ---
    paginator = Paginator(submissions, 18)
    page_number = request.GET.get('page')
    page_obj = paginator.get_page(page_number)

    # Fields for filter inputs (friendly labels)
    fields = [
        ('Submission_Time','Submission Time'),
        ('IP_Name','IP Name'),
        ('Sector','Sector'),
        ('Indicator','Indicator'),
        ('Date','Date'),
        ('Name','Name'),
        ('ID_Number','ID Number'),
        ('Parent_ID','Parent_ID'),
        ('Spouse_ID','Spouse_ID'),
        ('Phone_Number','Phone Number'),
        ('Date_of_Birth','Date of Birth'),
        ('Age','Age'),
        ('Gender','Gender'),
        ('Governorate','Governorate'),
        ('Household_ID','Household_ID'),
    ]

    context = {
        'submissions': page_obj,
        'filter_fields': fields,
        'request': request,  # for pagination links
        'total_records': submissions.count(),  # total after filtering
        'total_all_records': cnt,  # total in DB
        'current_sort': sort_field,  # current sorting
    }

    # AJAX request returns only table
    if request.headers.get('x-requested-with') == 'XMLHttpRequest':
        return render(request, 'myproject/inform_table.html', context)

    return render(request, 'myproject/inform_data.html', context)




# @login_required
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

# @login_required
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
    return redirect("login")  # Replace with your login URL name



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


# @login_required
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

# @login_required
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


class CustomPasswordChangeView(PasswordChangeView):
    form_class = StyledPasswordChangeForm
    template_name = "myproject/change_password.html"
    success_url = reverse_lazy('home')


# ------- ID_Number Duplication Section -----------------------------------------------------------

logger = logging.getLogger(__name__)
@login_required
def find_duplicates(request):
    """
    Page that finds duplicates in Beneficiary table grouped by id_number,
    and displays each duplicate set in its own table.
    """
    # Adjust `id_number` field name if your model uses different casing.
    # Group by id_number and keep groups with count>1
    duplicate_groups = (
        Beneficiary.objects
        .values("ID_Number")
        .annotate(count=Count("ID_Number"))
        .filter(count__gt=1)
        .order_by("-count")
    )

    # Build a list of groups where each group contains the actual records
    groups = []
    for g in duplicate_groups:
        ID_Number = g["ID_Number"]
        records = list(Beneficiary.objects.filter(ID_Number=ID_Number).order_by('-created_at'))
        groups.append({
            "ID_Number": ID_Number,
            "count": g["count"],
            "records": records,
        })

    context = {
        "groups": groups,
    }
    return render(request, "myproject/duplicates.html", context)


@require_POST
@login_required
def delete_inform(request, pk):
    """
    Deletes a single Beneficiary record (pk).
    Expects POST data:
      - delete_source: 'true' or 'false' (whether to attempt removal from InForm API)
    Returns JSON (success/error) — used by AJAX in the template.
    """
    if not request.user.is_authenticated:
        return HttpResponseForbidden("Authentication required.")

    delete_source = request.POST.get("delete_source", "false").lower() == "true"

    # Get target record
    obj = get_object_or_404(Beneficiary, pk=pk)
    inform_record_id = getattr(obj, "InForm_ID", None)  # adjust if field differs
    ip_name = getattr(obj, "IP_Name", None)

    if delete_source:
        if not inform_record_id:
            return JsonResponse({
                "success": False,
                "error": "Record has no linked InForm record id (InForm_ID). Cannot delete from InForm."
            }, status=400)

        # Look up the correct API token and form_id for this IP_Name
        try:
            api_token_entry = APIToken.objects.get(IP=ip_name)
            inform_api_token = api_token_entry.token
            inform_form_id = api_token_entry.form_id
        except APIToken.DoesNotExist:
            return JsonResponse({
                "success": False,
                "error": f"No API token configured for IP '{ip_name}'."
            }, status=400)

        # Attempt to delete via InForm API
        try:
            delete_url = f"https://data.inform.unicef.org/api/v1/data/{inform_form_id}/{inform_record_id}"
            headers = {"Authorization": f"Token {inform_api_token}"}
            resp = requests.delete(delete_url, headers=headers, timeout=15)

            if resp.status_code not in (200, 204):
                logger.error("InForm delete failed: %s - %s", resp.status_code, resp.text)
                return JsonResponse({
                    "success": False,
                    "error": f"InForm delete failed (status {resp.status_code}): {resp.text}"
                }, status=resp.status_code)
        except requests.RequestException as e:
            logger.exception("Error contacting InForm API")
            return JsonResponse({
                "success": False,
                "error": f"Error contacting InForm API: {str(e)}"
            }, status=500)

    # Delete the local DB record
    obj.soft_delete()

    return JsonResponse({"success": True, "deleted_pk": pk})

@require_POST
@login_required
def delete_duplicate(request, pk):
    """
    Deletes a single Beneficiary record (pk).
    Expects POST data:
      - delete_source: 'true' or 'false' (whether to attempt removal from InForm API)
    Returns JSON (success/error) — used by AJAX in the template.
    """
    if not request.user.is_authenticated:
        return HttpResponseForbidden("Authentication required.")

    delete_source = request.POST.get("delete_source", "false").lower() == "true"

    # Get target record
    obj = get_object_or_404(Beneficiary, pk=pk)
    inform_record_id = getattr(obj, "InForm_ID", None)  # adjust if field differs
    ip_name = getattr(obj, "IP_Name", None)

    if delete_source:
        if not inform_record_id:
            return JsonResponse({
                "success": False,
                "error": "Record has no linked InForm record id (InForm_ID). Cannot delete from InForm."
            }, status=400)

        # Look up the correct API token and form_id for this IP_Name
        try:
            api_token_entry = APIToken.objects.get(IP=ip_name)
            inform_api_token = api_token_entry.token
            inform_form_id = api_token_entry.form_id
        except APIToken.DoesNotExist:
            return JsonResponse({
                "success": False,
                "error": f"No API token configured for IP '{ip_name}'."
            }, status=400)

        # Attempt to delete via InForm API
        try:
            delete_url = f"https://data.inform.unicef.org/api/v1/data/{inform_form_id}/{inform_record_id}"
            headers = {"Authorization": f"Token {inform_api_token}"}
            resp = requests.delete(delete_url, headers=headers, timeout=15)

            if resp.status_code not in (200, 204):
                logger.error("InForm delete failed: %s - %s", resp.status_code, resp.text)
                return JsonResponse({
                    "success": False,
                    "error": f"InForm delete failed (status {resp.status_code}): {resp.text}"
                }, status=resp.status_code)
        except requests.RequestException as e:
            logger.exception("Error contacting InForm API")
            return JsonResponse({
                "success": False,
                "error": f"Error contacting InForm API: {str(e)}"
            }, status=500)

    # Delete the local DB record
    obj.soft_delete()

    return JsonResponse({"success": True, "deleted_pk": pk})

# (Optional) Bulk-delete endpoint if you want to delete an entire duplicate set by id_number
@require_POST
@login_required
def delete_duplicate_group(request):
    """
    Deletes all records in a duplicate set identified by ID_Number.
    Payload: ID_Number, delete_source (true/false).
    Uses APIToken table to resolve correct form_id/token per Beneficiary.IP_Name.
    """
    if not request.user.is_authenticated:
        return HttpResponseForbidden("Auth required.")

    ID_Number = request.POST.get("ID_Number")
    if not ID_Number:
        return JsonResponse({"success": False, "error": "Missing ID_Number."}, status=400)

    delete_source = request.POST.get("delete_source", "false").lower() == "true"

    qs = Beneficiary.objects.filter(ID_Number=ID_Number).order_by("id")
    results = []

    for obj in qs:
        pk = obj.pk
        inform_record_id = getattr(obj, "InForm_ID", None)
        ip_name = getattr(obj, "IP_Name", None)

        if delete_source:
            if not inform_record_id:
                results.append({"pk": pk, "status": "no_inform_id"})
                continue

            # Fetch API token & form_id dynamically from APIToken table
            try:
                api_token_entry = APIToken.objects.get(IP=ip_name)
                inform_api_token = api_token_entry.token
                inform_form_id = api_token_entry.form_id
            except APIToken.DoesNotExist:
                results.append({"pk": pk, "status": "no_api_token", "ip": ip_name})
                continue

            # Attempt remote delete
            delete_url = f"https://data.inform.unicef.org/api/v1/data/{inform_form_id}/{inform_record_id}"
            try:
                resp = requests.delete(delete_url, headers={"Authorization": f"Token {inform_api_token}"}, timeout=15)
                if resp.status_code not in (200, 204):
                    results.append({
                        "pk": pk,
                        "status": "remote_failed",
                        "http_status": resp.status_code,
                        "resp": resp.text
                    })
                    continue
            except requests.RequestException as e:
                results.append({"pk": pk, "status": "remote_error", "error": str(e)})
                continue

        # Local delete always happens
        obj.soft_delete()
        results.append({"pk": pk, "status": "deleted"})

    return JsonResponse({"success": True, "results": results})


# ---------- Beneficiary Details page ---------------------------------------------------------------

from django.shortcuts import render, get_object_or_404, redirect
from django.contrib import messages
from django.utils import timezone
import requests, uuid
from .models import Beneficiary

def safe_value(val):
    """Convert empty strings to None for API submission."""
    return val if val not in ["", None] else None


def get_form_id_string(ip_name):
    """Return correct Form_ID_String based on IP_Name."""
    mapping = {
        "AEI": "Beneficiary_Database_Form_Template",
        "UNRWA": "Beneficiary_Database_Form_Template_-_UNRWA",
        "WeWorld": "Beneficiary_Database_Form_Template_-_We_World",
        "MedGlobal": "azPSg7utHm6x4kNyfpdgCj",
        "RRM": "Beneficiary_Database_Form_Template_-_RRM",
        "NECC": "Beneficiary_Database_Form_Template_-_NECC",
    }
    return mapping.get(ip_name, "Beneficiary_Database_Form_Template_-_Default")


def beneficiary_details(request, record_id):
    record = get_object_or_404(Beneficiary, record_id=record_id)

    if request.method == "POST":
        # ---------- UPDATE LOCAL FIELDS ----------
        old_instance_id = record.InstanceID
        new_instance_id = f"uuid:{uuid.uuid4()}"

        record.IP_Name = safe_value(request.POST.get("IP_Name"))
        record.Sector = request.POST.get("Sector")
        record.Indicator = request.POST.get("Indicator")
        record.Date = safe_value(request.POST.get("Date"))
        record.Name = request.POST.get("Name")
        record.ID_Number = request.POST.get("ID_Number")
        record.Parent_ID = request.POST.get("Parent_ID")
        record.Spouse_ID = request.POST.get("Spouse_ID")
        record.Phone_Number = request.POST.get("Phone_Number")
        record.Date_of_Birth = safe_value(request.POST.get("Date_of_Birth"))
        record.Age = request.POST.get("Age")
        record.Gender = request.POST.get("Gender")
        record.Governorate = request.POST.get("Governorate")
        record.Municipality = request.POST.get("Municipality")
        record.Neighborhood = request.POST.get("Neighborhood")
        record.Site_Name = request.POST.get("Site_Name")
        record.Disability_Status = request.POST.get("Disability_Status")

        record.save()

        # ---------- Update Households ----------
        changes = assign_households()
        messages.success(request, f"Local record updated and household assignment updated for {changes} records.")

        # ---------- Prepare InForm Payload ----------
        form_id_string = get_form_id_string(record.IP_Name)
        inform_api_url = "https://data.inform.unicef.org/unicefstateofpalestine/submission"
        api_token = "ef5a72dad573916ed3a2289e51ca4f1b8ced5c88"  # replace with real one

        payload = {
            "id": form_id_string,
            "submission": {
                "start": None,
                "end": None,
                "Name": safe_value(record.Name),
                "ID_Number": safe_value(record.ID_Number),
                "Parent_ID": safe_value(record.Parent_ID),
                "Spouse_ID": safe_value(record.Spouse_ID),
                "Phone_Number": safe_value(record.Phone_Number),
                "Date_of_Birth": safe_value(record.Date_of_Birth),
                "Age": safe_value(record.Age),
                "Gender": safe_value(record.Gender),
                "Governorate": safe_value(record.Governorate),
                "Municipality": safe_value(record.Municipality),
                "Neighborhood": safe_value(record.Neighborhood),
                "Site_Name": safe_value(record.Site_Name),
                "Disability_Status": safe_value(record.Disability_Status),
                "Sector": safe_value(record.Sector),
                "IP_Name": safe_value(record.IP_Name),
                "Indicator": safe_value(record.Indicator),
                "Date": safe_value(record.Date),
                "meta": {
                    "instanceID": new_instance_id,
                    "deprecatedID": old_instance_id,
                },
            },
        }

        headers = {
            "Authorization": f"Token {api_token}",
            "Content-Type": "application/json",
        }

        # ---------- Send to InForm ----------
        try:
            response = requests.post(inform_api_url, headers=headers, json=payload, timeout=20)
            if response.status_code in [200, 201]:
                record.InstanceID = new_instance_id
                record.save()
                messages.success(request, "✅ Record updated successfully and synced to InForm.")
            else:
                messages.warning(
                    request,
                    f"⚠️ Local update saved but InForm sync failed ({response.status_code}): {response.text}",
                )
        except Exception as e:
            messages.error(request, f"❌ Local update saved but failed to connect to InForm: {str(e)}")

        return redirect("beneficiary_details", record_id=record.record_id)

    # ---------- GET request: display details page ----------
    return render(request, "myproject/beneficiary_details.html", {"record": record})



# ---------- Inform Details page ---------------------------------------------------------------

def inform_details(request, record_id):
    record = get_object_or_404(Beneficiary, record_id=record_id)
    return redirect("beneficiary_details", record_id=record.record_id)



# ---------- Household Details page ---------------------------------------------------------------


@login_required
def household_details(request, household_id):
    # Get all members in this household
    members = Beneficiary.objects.filter(Household_ID=household_id)

    if not members.exists():
        raise Http404("Household not found")

    # Identify potential head (Parent_ID is empty, usually the head)
    head = next((m for m in members if not m.Parent_ID), members.first())

    # Build relationship mapping
    relationships = []
    for member in members:
        relation = "Head" if member == head else "Spouse" if member.Spouse_ID == head.ID_Number else "Child"
        relationships.append({
            "relation": relation,
            "member": member,
        })

    context = {
        "household_id": household_id,
        "head": head,
        "relationships": relationships,
        "total_members": members.count(),
    }
    return render(request, "myproject/household_details.html", context)

@login_required
def deleted_beneficiaries(request):
    deleted_records = Beneficiary.deleted_objects.order_by('-deleted_at')
    
    if request.method == "POST":
        pk = request.POST.get("pk")
        if pk:
            record = get_object_or_404(Beneficiary.deleted_objects, pk=pk)
            record.Deleted = False
            record.save()
            messages.success(request, f"Record {record.ID_Number or record.InForm_ID} restored successfully.")
            return redirect('deleted_beneficiaries')

    return render(request, "myproject/deleted_beneficiaries.html", {"records": deleted_records})
