from django.shortcuts import render
from django.http import HttpResponse
from .inform_api import get_form_submissions
import requests
from django.shortcuts import redirect
from .models import Submission
from django.contrib import messages
from datetime import datetime


# Create your views here.

def home(request):
    return render(request, 'myproject/home.html')

def get_item(dictionary, key):
    if isinstance(dictionary, dict):
        return dictionary.get(key, "")
    return ""

def sync_inform_data(request):
    form_id = 8199  # e.g., "beneficiaries_form_2024"
    try:
        submissions = get_form_submissions(int(form_id))
        new_count = 0
        for item in submissions:
            record_id = get_item(item, "_id")
            name=get_item(item, "Name")
            date_of_birth=get_item(item, "Date_Of_Birth")
            
            if not Submission.objects.filter(record_id=record_id).exists():
                Submission.objects.create(
                    record_id=record_id,
                    name=name,
                    date_of_birth = date_of_birth
                )
                new_count += 1

        
        messages.success(request, f"✅ Sync complete: {new_count} new records added.")
        print(f"✅ Sync complete: {new_count} new records added.")
    except Exception as e:
        submissions = []
        messages.error(request, str(e))

        print(str(e))
    
    return redirect("home")

def inform_data_view(request):
    submissions = Submission.objects.all().order_by('-id')  # newest first
    return render(request, 'myproject/inform_data.html', {'submissions': submissions})