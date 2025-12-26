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

# global variable for progress
progress_status = {"stage": "Not started", "progress": 0}

@login_required
def sync_data(request):
    global progress_status
    
    if request.method != 'POST':
        return JsonResponse({"status": "error", "message": "Invalid request method. Only POST allowed.", "extra_tags":"auto"})

    # Reset before new run
    progress_status = {"stage": "Starting sync ...", "progress": 1, "completed": False}

    def run_sync():
        global progress_status
        tokens = APIToken.objects.all()
        if not tokens.exists():
            progress_status = {"stage": "❌ No API tokens available.", "progress": 0, "completed": True}
            return

        total_fetched = 0
        new_count = 0
        duplicate_count = 0
        invalid_date_count = 0

        # iterate tokens but do NOT let one token failure abort everything
        for token in tokens:
            token_id = getattr(token, "form_id", str(token.pk))
            page = 1
            page_size = 10000

            # token-level try so we continue to next token on failure
            try:
                while True:
                    url = f"https://data.inform.unicef.org/api/v1/data/{token.form_id}.json?page={page}&page_size={page_size}"
                    headers = {"Authorization": f"Token {token.token}", "Content-Type": "application/json"}

                    try:
                        response = requests.get(url, headers=headers, timeout=30)
                    except requests.RequestException as e:
                        # network/timeout error — report and continue to next token
                        progress_status = {
                            "stage": f"⚠️ Network error for token {token_id}: {str(e)}",
                            "progress": 0,
                            "completed": False,
                        }
                        break  # stop pages for this token, move to next token

                    if response.status_code == 401 or response.status_code == 403:
                        # unauthorized for this token — skip token
                        progress_status = {
                            "stage": f"⚠️ Auth failed for token {token_id} (HTTP {response.status_code}) — skipping token",
                            "progress": 0,
                            "completed": False,
                        }
                        break

                    if response.status_code != 200:
                        # other non-200 — log and stop paging this token
                        progress_status = {
                            "stage": f"⚠️ Failed fetching token {token_id} page {page} (HTTP {response.status_code})",
                            "progress": 0,
                            "completed": False,
                        }
                        break

                    # parse JSON safely
                    try:
                        data = response.json()
                        # ✅ Stop when there’s no data or an empty page
                        if not data or (isinstance(data, dict) and not data.get("data") and not data.get("results")):
                            break
                        # If API wraps data under "data"
                        if isinstance(data, dict) and "data" in data:
                            data = data["data"]

                        if len(data) == 0:
                            break

                        total_fetched += len(data)
                    except ValueError:
                        progress_status = {
                            "stage": f"⚠️ Invalid JSON for token {token_id} page {page} — skipping token",
                            "progress": 0,
                            "completed": False,
                        }
                        break

                    if not data:
                        # no more pages
                        break

                    # increment totals for reporting
                    #total_fetched += len(data)

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

                        # progress update (per-record)
                        progress_status = {
                            "stage": f"IP: {get_val('IP_Name')} | Form: {token_id} | Page: {page} | Record:({idx}/{len(data)})",
                            # show progress up to 98 while running; final will be 100 when done
                            "progress": min(98, int((idx / max(len(data), 1)) * 100)),
                            "new_count": new_count,
                            "duplicate_count": duplicate_count,
                            "invalid_date_count": invalid_date_count,
                            "total_fetched": total_fetched,
                            "completed": False,
                        }

                        instanceid = f"uuid:{get_val('_uuid')}"
                        # Try to find an existing beneficiary with this InForm_ID
                        beneficiary = Beneficiary.all_objects.filter(InstanceID=instanceid).first()

                        if not beneficiary or not beneficiary.InForm_ID:
                            # Create new record only if not found or InForm_ID is empty
                            Beneficiary.all_objects.update_or_create(
                                record_id=get_val("_id"),
                                defaults={
                                    "record_id": get_val("_id"),
                                    "InForm_ID": get_val("_id"),
                                    "InstanceID": instanceid,
                                    "IP_Name": get_val("IP_Name"),
                                    "Sector": get_val("Sector"),
                                    "Indicator": get_val("Indicator"),
                                    "Date": get_val("Date"),
                                    "Name": get_val("Name"),
                                    "ID_Number": get_val("ID_Number"),
                                    "Parent_ID": get_val("Parent_ID"),
                                    "Spouse_ID": get_val("Spouse_ID"),
                                    "Phone_Number": get_val("Phone_Number"),
                                    "Date_of_Birth": get_val("Date_of_Birth"),
                                    "Age": get_val("Age"),
                                    "Gender": get_val("Gender"),
                                    "Governorate": get_val("Governorate"),
                                    "Municipality": get_val("Municipality"),
                                    "Neighborhood": get_val("Neighborhood"),
                                    "Site_Name": get_val("Site_Name"),
                                    "Disability_Status": get_val("Disability_Status"),
                                    "Submission_Time": get_val("_submission_time"),
                                    "Deleted": get_val("Deleted"),
                                    "deleted_at": get_val("deleted_at"),
                                    "undeleted_at": get_val("undeleted_at"),
                                }
                            )
                        new_count += 1

                    # next page for this token
                    # ✅ Move to next page only if this page was full
                    if len(data) < page_size:
                        # means this was the last page
                        break

                    page += 1

            except Exception as e_token:
                # catch unexpected exceptions for this token and continue to the next
                progress_status = {
                    "stage": f"❌ Unexpected error while processing token {token_id}: {str(e_token)}",
                    "progress": 0,
                    "completed": False,
                }
                # continue to next token
                continue

        # After all tokens processed, assign households and produce final summary
        try:
            changes = assign_households()
            messages.success(request, f"Household assignment updated for {changes} records.", extra_tags="auto")
        except Exception as e_house:
            changes = 0
            # log or include house error in the status
            progress_status = {
                "stage": f"⚠️ Household assignment error: {str(e_house)}",
                "progress": 100,
                "completed": True,
            }
        messages.success(request, f"Household assignment updated for {changes} records.", extra_tags="auto")

        progress_status = {
            "stage": "✅ Sync completed",
            "progress": 100,
            "new_count": new_count,
            "duplicate_count": duplicate_count,
            "invalid_date_count": invalid_date_count,
            "total_fetched": total_fetched,
            "household_changes": changes,
            "completed": True,
            "extra_tags":"auto"
        }

    thread = threading.Thread(target=run_sync, daemon=True)
    thread.start()

    return JsonResponse({"status": "started"})

    

    


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
            messages.success(request, "✅ Token saved successfully.", extra_tags="auto")
            return redirect('manage_tokens')
        else:
            messages.error(request, "❌ Please correct the errors below.", extra_tags="auto")
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
    messages.success(request, "API token deleted successfully.", extra_tags="auto")
    return redirect('manage_tokens')  # Redirect back to the manage tokens page

def user_login(request):
    if request.method == 'POST':
        form = AuthenticationForm(request, data=request.POST)
        if form.is_valid():
            user = form.get_user()
            login(request, user)
            messages.success(request, "You have successfully logged in.", extra_tags="auto")
            return redirect('home')  # Redirect to your desired page
        else:
            messages.error(request, "Invalid username or password.", extra_tags="auto")
    else:
        form = AuthenticationForm()

    context = {
        'form': form,
    }
    return render(request, 'myproject/login.html', context)

def user_logout(request):
    logout(request)
    messages.success(request, "You have been logged out.", extra_tags="auto")
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
                messages.error(request, "Username already exists.", extra_tags="auto")
            elif User.objects.filter(email=email).exists():
                messages.error(request, "Email is already registered.", extra_tags="auto")
            else:
                user = User.objects.create_user(username=username, email=email, first_name=first_name, last_name=last_name, password=password)
                user.is_active = True  # 🔑 make sure the account is active
                user.save()
                print(user.password)
                messages.success(request, "Account created successfully! Please log in.", extra_tags="auto")
                return redirect('login')
        else:
            messages.error(request, "Passwords do not match.", extra_tags="auto")
    return render(request, 'myproject/register.html')


# @login_required
def profile(request):
    if request.method == "POST":
        user = request.user
        user.first_name = request.POST.get("first_name")
        user.last_name = request.POST.get("last_name")
        user.email = request.POST.get("email")
        user.save()
        messages.success(request, "User profile updated successfully!", extra_tags="auto")
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
            messages.success(request, "✅ Your password was successfully updated!", extra_tags="auto")
            return redirect("home")  # redirect to profile or dashboard
        else:
            messages.error(request, "❌ Please correct the errors below.", extra_tags="auto")
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
    total_records = 0
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
        total_records += len(records)

    context = {
        "groups": groups,
        "total_duplicates": len(groups),
        "total_records": total_records,
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

        # ---------- Prepare InForm Payload ----------
        form_id_string = get_form_id_string(obj.IP_Name)
        inform_api_url = "https://data.inform.unicef.org/unicefstateofpalestine/submission"
        api_token = "ef5a72dad573916ed3a2289e51ca4f1b8ced5c88"  # replace with real one
        new_instance_id = f"uuid:{str(uuid.uuid4())}"
        obj.Deleted = True
        obj.deleted_at = timezone.now().strftime("%Y-%m-%dT%H:%M:%S")

        payload = {
            "id": form_id_string,
            "submission": {
                "IP_Name": obj.IP_Name,
                "Sector": obj.Sector,
                "Indicator": obj.Indicator,
                "Date": obj.Date,
                "Name": obj.Name,
                "ID_Number": obj.ID_Number,
                "Parent_ID": obj.Parent_ID,
                "Spouse_ID": obj.Spouse_ID,
                "Phone_Number": obj.Phone_Number,
                "Date_of_Birth": obj.Date_of_Birth,
                "Age": obj.Age,
                "Gender": obj.Gender,
                "Governorate": obj.Governorate,
                "Municipality": obj.Municipality,
                "Neighborhood": obj.Neighborhood,
                "Site_Name": obj.Site_Name,
                "Disability_Status": obj.Disability_Status,
                "Deleted": obj.Deleted,
                "deleted_at": obj.deleted_at,
                "undeleted_at": obj.undeleted_at.strftime("%Y-%m-%dT%H:%M:%S") if obj.undeleted_at else None,
                "meta": {
                    "instanceID": new_instance_id,
                    "deprecatedID": obj.InstanceID,
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
                obj.InstanceID = new_instance_id
                obj.save()
                messages.success(request, "✅ Record has been deleted successfully and synced to InForm.", extra_tags="auto")
            else:
                messages.warning(
                    request,
                    f"⚠️ Local update saved but InForm sync failed ({response.status_code}): {response.text}",
                    extra_tags="auto"
                )
        except Exception as e:
            messages.error(request, f"❌ Local update saved but failed to connect to InForm: {str(e)}", extra_tags="auto")

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

        # ---------- Prepare InForm Payload ----------
    if delete_source:
        form_id_string = get_form_id_string(obj.IP_Name)
        inform_api_url = "https://data.inform.unicef.org/unicefstateofpalestine/submission"
        api_token = "ef5a72dad573916ed3a2289e51ca4f1b8ced5c88"  # replace with real one
        new_instance_id = f"uuid:{str(uuid.uuid4())}"
        obj.Deleted = True
        obj.deleted_at = timezone.now().strftime("%Y-%m-%dT%H:%M:%S")

        payload = {
            "id": form_id_string,
            "submission": {
                "IP_Name": obj.IP_Name,
                "Sector": obj.Sector,
                "Indicator": obj.Indicator,
                "Date": obj.Date,
                "Name": obj.Name,
                "ID_Number": obj.ID_Number,
                "Parent_ID": obj.Parent_ID,
                "Spouse_ID": obj.Spouse_ID,
                "Phone_Number": obj.Phone_Number,
                "Date_of_Birth": obj.Date_of_Birth,
                "Age": obj.Age,
                "Gender": obj.Gender,
                "Governorate": obj.Governorate,
                "Municipality": obj.Municipality,
                "Neighborhood": obj.Neighborhood,
                "Site_Name": obj.Site_Name,
                "Disability_Status": obj.Disability_Status,
                "Deleted": obj.Deleted,
                "deleted_at": obj.deleted_at,
                "undeleted_at": obj.undeleted_at.strftime("%Y-%m-%dT%H:%M:%S") if obj.undeleted_at else None,
                "meta": {
                    "instanceID": new_instance_id,
                    "deprecatedID": obj.InstanceID,
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
                obj.InstanceID = new_instance_id
                obj.save()
                messages.success(request, "✅ Record has been deleted successfully and synced to InForm.", extra_tags="auto")
            else:
                messages.warning(
                    request,
                    f"⚠️ Local update saved but InForm sync failed ({response.status_code}): {response.text}",
                    extra_tags="auto"
                )
        except Exception as e:
            messages.error(request, f"❌ Local update saved but failed to connect to InForm: {str(e)}", extra_tags="auto")

    # Delete the local DB record
    obj.soft_delete()
    messages.success(request, "✅ Record has been deleted successfully from local database.", extra_tags="auto")

    return JsonResponse({"success": True, "deleted_pk": pk})


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


def beneficiary_details(request, pk):
    record = get_object_or_404(Beneficiary, pk=pk)

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
        messages.success(request, f"Local record updated and household assignment updated for {changes} records.", extra_tags="auto")

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
                messages.success(request, "✅ Record updated successfully and synced to InForm.", extra_tags="auto")
            else:
                messages.warning(
                    request,
                    f"⚠️ Local update saved but InForm sync failed ({response.status_code}): {response.text}",
                    extra_tags="auto"
                )
        except Exception as e:
            messages.error(request, f"❌ Local update saved but failed to connect to InForm: {str(e)}", extra_tags="auto")

        return redirect("beneficiary_details", pk=record.pk)
    
    
    # Prepare filter options
    ip_list = APIToken.objects.values_list('IP', flat=True).distinct().order_by('IP')
    sector_list = APIToken.objects.values_list('section', flat=True).distinct().order_by('section')

    context = {
        "record": record,
        'ip_list': ip_list,
        'sector_list': sector_list,
        # include any other variables you already had in context
    }
    # ---------- GET request: display details page ----------
    return render(request, "myproject/beneficiary_details.html", context)



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

# ---------- Deleted Beneficiaries page ---------------------------------------------------------------

@login_required
def deleted_beneficiaries(request):
    deleted_records = Beneficiary.deleted_objects.order_by('-deleted_at')
    
    if request.method == "POST":
        pk = request.POST.get("pk")
        if pk:
            record = get_object_or_404(Beneficiary.deleted_objects, pk=pk)
            record.Deleted = False
            record.undeleted_at = timezone.now().strftime("%Y-%m-%dT%H:%M:%S")
            # ---------- Prepare InForm Payload ----------
            form_id_string = get_form_id_string(record.IP_Name)
            inform_api_url = "https://data.inform.unicef.org/unicefstateofpalestine/submission"
            api_token = "ef5a72dad573916ed3a2289e51ca4f1b8ced5c88"  # replace with real one
            new_instance_id = f"uuid:{str(uuid.uuid4())}"

            payload = {
                "id": form_id_string,
                "submission": {
                    "IP_Name": record.IP_Name,
                    "Sector": record.Sector,
                    "Indicator": record.Indicator,
                    "Date": record.Date,
                    "Name": record.Name,
                    "ID_Number": record.ID_Number,
                    "Parent_ID": record.Parent_ID,
                    "Spouse_ID": record.Spouse_ID,
                    "Phone_Number": record.Phone_Number,
                    "Date_of_Birth": record.Date_of_Birth,
                    "Age": record.Age,
                    "Gender": record.Gender,
                    "Governorate": record.Governorate,
                    "Municipality": record.Municipality,
                    "Neighborhood": record.Neighborhood,
                    "Site_Name": record.Site_Name,
                    "Disability_Status": record.Disability_Status,
                    "Deleted": record.Deleted,
                    "deleted_at": record.deleted_at.strftime("%Y-%m-%dT%H:%M:%S") if record.undeleted_at else None,
                    "undeleted_at": record.undeleted_at,
                    "meta": {
                        "instanceID": new_instance_id,
                        "deprecatedID": record.InstanceID,
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
                    messages.success(request, "✅ Record has been restored successfully and synced to InForm.", extra_tags="auto")
                else:
                    messages.warning(
                        request,
                        f"⚠️ Local update saved but InForm sync failed ({response.status_code}): {response.text}",
                        extra_tags="auto"
                    )
            except Exception as e:
                messages.error(request, f"❌ Local update saved but failed to connect to InForm: {str(e)}", extra_tags="auto")            
            record.save()
            #messages.success(request, f"Record {record.ID_Number or record.InForm_ID} restored successfully.", extra_tags="auto")
            return redirect('deleted_beneficiaries')

    return render(request, "myproject/deleted_beneficiaries.html", {"records": deleted_records})


# ---------- Adding Beneficiaries page ---------------------------------------------------------------

import uuid
import requests
from django.shortcuts import render, redirect
from django.contrib import messages
from django.http import JsonResponse
from django.contrib.auth.decorators import login_required
from .models import Beneficiary
from .households import assign_households


@login_required
def beneficiary_add(request):
    if request.method == "POST":
        id_number = request.POST.get("ID_Number")
        
        # 🔹 Step 1: Check duplicates locally
        duplicates = Beneficiary.all_objects.filter(ID_Number=id_number)
        if duplicates.exists():
            messages.warning(request, f"⚠️ Duplicate beneficiaries found with ID {id_number}.", extra_tags="auto")
            return render(request, "myproject/duplicate_list.html", {"duplicates": duplicates})

        # 🔹 Step 2: Prepare payload for InForm API
        new_instance_id = f"uuid:{uuid.uuid4()}"
        form_data = {
            "IP_Name": safe_value(request.POST.get("IP_Name")),
            "Sector": safe_value(request.POST.get("Sector")),
            "Indicator": safe_value(request.POST.get("Indicator")),
            "Date": safe_value(request.POST.get("Date")),
            "Name": safe_value(request.POST.get("Name")),
            "ID_Number": safe_value(request.POST.get("ID_Number")),
            "Parent_ID": safe_value(request.POST.get("Parent_ID")),
            "Spouse_ID": safe_value(request.POST.get("Spouse_ID")),
            "Phone_Number": safe_value(request.POST.get("Phone_Number")),
            "Date_of_Birth": safe_value(request.POST.get("Date_of_Birth")),
            "Age": safe_value(request.POST.get("Age")),
            "Gender": safe_value(request.POST.get("Gender")),
            "Governorate": safe_value(request.POST.get("Governorate")),
            "Municipality": safe_value(request.POST.get("Municipality")),
            "Neighborhood": safe_value(request.POST.get("Neighborhood")),
            "Site_Name": safe_value(request.POST.get("Site_Name")),
            "Disability_Status": safe_value(request.POST.get("Disability_Status")),
        }

        # --- Prepare InForm API payload ---
        api_token = "ef5a72dad573916ed3a2289e51ca4f1b8ced5c88"  # your real API token
        inform_api_url = "https://data.inform.unicef.org/unicefstateofpalestine/submission"
        form_id_string = get_form_id_string(form_data["IP_Name"])  # your helper

        payload = {
            "id": form_id_string,
            "submission": {
                **form_data,
                "meta": {
                    "instanceID": new_instance_id,
                },
            },
        }

        headers = {
            "Authorization": f"Token {api_token}",
            "Content-Type": "application/json",
        }

        # 🔹 Step 3: Submit to InForm API
        try:
            response = requests.post(inform_api_url, headers=headers, json=payload, timeout=20)

            if response.status_code in [200, 201]:

                # 🔹 Step 4: Get the InForm -id
                



                # 🔹 Step 4: Sync this record only to local DB
                submission_data = payload["submission"]
                record = Beneficiary(
                    InForm_ID=inform_id,
                    record_id=inform_id,
                    IP_Name=submission_data.get("IP_Name"),
                    Sector=submission_data.get("Sector"),
                    Indicator=submission_data.get("Indicator"),
                    Date=submission_data.get("Date"),
                    Name=submission_data.get("Name"),
                    ID_Number=submission_data.get("ID_Number"),
                    Parent_ID=submission_data.get("Parent_ID"),
                    Spouse_ID=submission_data.get("Spouse_ID"),
                    Phone_Number=submission_data.get("Phone_Number"),
                    Date_of_Birth=submission_data.get("Date_of_Birth"),
                    Age=submission_data.get("Age"),
                    Gender=submission_data.get("Gender"),
                    Governorate=submission_data.get("Governorate"),
                    Municipality=submission_data.get("Municipality"),
                    Neighborhood=submission_data.get("Neighborhood"),
                    Site_Name=submission_data.get("Site_Name"),
                    Disability_Status=submission_data.get("Disability_Status"),
                    InstanceID=new_instance_id,
                )
                record.save()

                # 🔹 Step 5: Update household relationships
                changes = assign_households()
                messages.success(request, f"✅ Beneficiary added & synced. Household updated for {changes} records.", extra_tags="auto")

            else:
                messages.error(
                    request,
                    f"❌ Failed to add to InForm (status {response.status_code}): {response.text}",
                    extra_tags="auto"
                )

        except Exception as e:
            messages.error(request, f"❌ Failed to connect to InForm: {str(e)}", extra_tags="auto")

        return redirect("/")


    ip_list = APIToken.objects.values_list('IP', flat=True).distinct().order_by('IP')
    sector_list = APIToken.objects.values_list('section', flat=True).distinct().order_by('section')

    context = {
        'ip_list': ip_list,
        'sector_list': sector_list,
        # include any other variables you already had in context
    }

    # GET request → render the Add form
    return render(request, "myproject/beneficiary_add.html", context)



# ---------- Manually run Assiogn_Households ---------------------------------------------------------------

@login_required
def assign_households_view(request):
    try:
        # Run your existing Python function
        result = assign_households()
        return JsonResponse({"status": "success", "message": "Households reassigned successfully."})
    except Exception as e:
        return JsonResponse({"status": "error", "message": str(e)})

