from django.shortcuts import render, redirect
from django.contrib import messages
from .inform_api import get_form_submissions
from .models import Submission
from datetime import datetime
from django.core.paginator import Paginator
from django.http import JsonResponse
from django.utils.timezone import localtime


def home(request):
    last_sync_record = Submission.objects.order_by('-created_at').first()
    last_sync_time = localtime(last_sync_record.created_at).strftime("%Y-%m-%d %H:%M") if last_sync_record else "Never"
    return render(request, 'myproject/home.html', {'last_sync_time': last_sync_time})

def get_item(dictionary, key):
    if isinstance(dictionary, dict):
        return dictionary.get(key, "")
    return ""

def sync_inform_data(request):
    if request.method == "POST":
        try:
            submissions = get_form_submissions(8199)
            new_count = 0
            duplicate_count = 0
            invalid_count = 0

            for item in submissions:
                record_id = get_item(item, "_id")
                name = get_item(item, "name")
                date_of_birth = get_item(item, "date_Of_birth")
                

                # Validate date format
                parsed_date = None
                if date_of_birth:
                    try:
                        parsed_date = datetime.strptime(date_of_birth, "%Y-%m-%d").date()
                    except ValueError:
                        invalid_count += 1

                if not Submission.objects.filter(record_id=record_id).exists():
                    Submission.objects.create(record_id=record_id, name=name, date_of_birth=parsed_date, section = 'Health')
                    new_count += 1
                else:
                    duplicate_count += 1

            last_sync = localtime().strftime("%Y-%m-%d %H:%M")
            message = f"✅ Sync completed: {new_count} added, {duplicate_count} total records."

            if request.headers.get("X-Requested-With") == "XMLHttpRequest":
                return JsonResponse({"status": "success", "message": message, "last_sync": last_sync})

            messages.success(request, message)
        except Exception as e:
            error_message = f"❌ Sync failed: {str(e)}"
            if request.headers.get("X-Requested-With") == "XMLHttpRequest":
                return JsonResponse({"status": "error", "message": error_message})
            messages.error(request, error_message)

    return redirect("home")


def inform_data_view(request):
    submissions_list = Submission.objects.all().order_by('-created_at')
    paginator = Paginator(submissions_list, 20)  # Show 20 per page
    page_number = request.GET.get('page')
    submissions = paginator.get_page(page_number)

    return render(request, 'myproject/inform_data.html', {'submissions': submissions})

