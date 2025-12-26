from django.shortcuts import render, redirect, get_object_or_404
from django.views.generic import ListView, DetailView
from django.contrib import messages
from django.shortcuts import redirect
from .models import Workspace, Channel, Flow, Contact, FlowRun, APIToken
from .services import RapidProService
from django.conf import settings
from django.http import HttpResponse, JsonResponse
import matplotlib.pyplot as plt
import io
import base64
import matplotlib
from django.core.paginator import EmptyPage, PageNotAnInteger, Paginator
import threading
from django.urls import reverse
from django.db.models import Count, F
import requests
from time import timezone
from django.contrib.auth.decorators import login_required
from django.contrib.auth.models import User
from collections import Counter
import pandas as pd
import matplotlib.pyplot as plt
import io
import base64
from .forms import APITokenForm
#from rest_framework import serializers
from rest_framework.views import APIView
from rest_framework.response import Response
from .serializers import WorkspaceSerializer, ContactSerializer, ChannelSerializer, FlowSerializer, FlowRunSerializer



try:
    matplotlib.use('Agg')
except Exception as e:
    print(f"Error setting matplotlib backend: {e}")



@login_required
def manage_tokens(request):
    if request.method == 'POST':
        form = APITokenForm(request.POST)
        if form.is_valid():
            form.save()
            return redirect('manage_tokens')  # Redirect to the same page after saving
    else:
        form = APITokenForm()

    tokens = APIToken.objects.all()
    return render(request, 'rapidpro_app/manage_tokens.html', {'form': form, 'tokens': tokens})

def delete_token(request, pk):
    token = get_object_or_404(APIToken, pk=pk)
    token.delete()
    messages.success(request, "API token deleted successfully.")
    return redirect('manage_tokens')  # Redirect back to the manage tokens page

class WorkspaceListView(ListView):
    model = Workspace
    template_name = 'rapidpro_app/workspace_list.html'
    context_object_name = 'workspaces'

class ChannelListView(ListView):
    model = Channel
    template_name = 'rapidpro_app/channel_list.html'
    context_object_name = 'channels'
    paginate_by = 100  # Adjust this value for default pagination items

    def get_queryset(self):
        workspace_id = self.request.GET.get('workspace_id')
        self.workspace_id = workspace_id  # Store for context
        
        
        if workspace_id == 'all':
            queryset = Channel.objects.all().order_by('-created_on')
        else:
            queryset = Channel.objects.filter(wsuuid=workspace_id).order_by('-created_on')
        
        if not queryset.exists() and workspace_id == 'all':
            queryset = Channel.objects.all().order_by('-created_on')
        else:
            queryset.exists() == True    
        return queryset

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        queryset = self.get_queryset()
        paginator = Paginator(queryset, self.paginate_by)
        page = self.request.GET.get('page')

        try:
            page_obj = paginator.get_page(page)
        except PageNotAnInteger:
            page_obj = paginator.get_page(1)
        except EmptyPage:
            page_obj = paginator.get_page(paginator.num_pages)

        context['page_obj'] = page_obj
        context['is_paginated'] = paginator.num_pages > 1
        context['channels'] = page_obj.object_list  # Ensure the current page's queryset is used
        context['wsuuid'] = self.workspace_id

        # Calculate dynamic pagination range
        current_page = page_obj.number
        total_pages = paginator.num_pages

        if total_pages <= 10:
            page_range = range(1, total_pages + 1)
        else:
            start = max(current_page - 2, 1)
            end = min(current_page + 2, total_pages)
            page_range = list(range(start, end + 1))

            if start > 2:
                page_range = [1, 2, '...'] + page_range
            if end < total_pages - 1:
                page_range = page_range + ['...', total_pages - 1, total_pages]

        context['page_range'] = page_range
        return context   


class FlowListView(ListView):
    model = Flow
    template_name = 'rapidpro_app/flow_list.html'
    context_object_name = 'flows'
    paginate_by = 20  # Default items per page, can be changed dynamically

    def get_queryset(self):
        workspace_id = self.request.GET.get('workspace_id')
        self.workspace_id = workspace_id  # Store for context
        

        if workspace_id == 'all':
            queryset = Flow.objects.all().order_by('-created_on')
        else:
            queryset = Flow.objects.filter(wsuuid=workspace_id).order_by('-created_on')

        if not queryset.exists() and workspace_id == 'all':
            queryset = Flow.objects.all().order_by('-created_on')
        elif not queryset.exists() and workspace_id != 'all':
            queryset = FlowRun.objects.filter(wsuuid=workspace_id).order_by('-created_on')
        return queryset

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        queryset = self.get_queryset()

        # Handle pagination
        paginator = Paginator(queryset, self.paginate_by)
        page = self.request.GET.get('page')

        try:
            page_obj = paginator.get_page(page)
        except PageNotAnInteger:
            # If page is not an integer, deliver the first page.
            page_obj = paginator.get_page(1)
        except EmptyPage:
            # If the page is out of range, deliver the last page of results.
            page_obj = paginator.get_page(paginator.num_pages)

        context['page_obj'] = page_obj
        context['is_paginated'] = paginator.num_pages > 1
        context['flows'] = page_obj.object_list  # Ensure the current page's queryset is used
        context['wsuuid'] = self.workspace_id  # Pass workspace_id to the template
        if self.request.GET.get('page') == None:
            context['flowpage'] = '1'
        else:
            context['flowpage'] = self.request.GET.get('page')
        
        # Calculate dynamic pagination range
        current_page = page_obj.number
        total_pages = paginator.num_pages

        if total_pages <= 10:
            page_range = range(1, total_pages + 1)
        else:
            start = max(current_page - 2, 1)
            end = min(current_page + 2, total_pages)
            page_range = list(range(start, end + 1))

            if start > 2:
                page_range = [1, 2, '...'] + page_range
            if end < total_pages - 1:
                page_range = page_range + ['...', total_pages - 1, total_pages]

        context['page_range'] = page_range
        return context    
    

class ContactListView(ListView):
    model = Contact
    template_name = 'rapidpro_app/contact_list.html'
    context_object_name = 'contacts'
    paginate_by = 20  # Adjust this value for default pagination items

    def get_queryset(self):
        workspace_id = self.request.GET.get('workspace_id')
        self.workspace_id = workspace_id  # Store for context
        
        
        if workspace_id == 'all':
            queryset = Contact.objects.all().order_by('-created_on')
        else:
            queryset = Contact.objects.filter(wsuuid=workspace_id).order_by('-created_on')
        
        if not queryset.exists() and workspace_id == 'all':
            queryset = Contact.objects.all().order_by('-created_on')
        else:
            queryset.exists() == True    
        return queryset

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        queryset = self.get_queryset()
        paginator = Paginator(queryset, self.paginate_by)
        page = self.request.GET.get('page')

        try:
            page_obj = paginator.get_page(page)
        except PageNotAnInteger:
            page_obj = paginator.get_page(1)
        except EmptyPage:
            page_obj = paginator.get_page(paginator.num_pages)

        context['page_obj'] = page_obj
        context['is_paginated'] = paginator.num_pages > 1
        context['contacts'] = page_obj.object_list  # Ensure the current page's queryset is used
        context['wsuuid'] = self.workspace_id
        
        # Calculate dynamic pagination range
        current_page = page_obj.number
        total_pages = paginator.num_pages

        if total_pages <= 10:
            page_range = range(1, total_pages + 1)
        else:
            start = max(current_page - 2, 1)
            end = min(current_page + 2, total_pages)
            page_range = list(range(start, end + 1))

            if start > 2:
                page_range = [1, 2, '...'] + page_range
            if end < total_pages - 1:
                page_range = page_range + ['...', total_pages - 1, total_pages]

        context['page_range'] = page_range
        return context    

class FlowRunListView(ListView):
    model = FlowRun
    template_name = 'rapidpro_app/flowrun_list.html'
    context_object_name = 'flowruns'
    paginate_by = 20  # Adjust this value for default pagination items

    def get_queryset(self):
        workspace_id = self.request.GET.get('workspace_id')
        self.workspace_id = workspace_id  # Store for context
        flow_id = self.request.GET.get('flow_id')
        self.flow_id = flow_id  # Store for context

        if workspace_id == 'all':
            queryset = FlowRun.objects.all().order_by('-created_on')
        else:
            queryset = FlowRun.objects.filter(wsuuid=workspace_id).order_by('-created_on')
            
        if flow_id == 'all':
            queryset = queryset.all().order_by('-created_on')
        else:
            queryset = queryset.filter(flowuuid=flow_id).order_by('-created_on')
        return queryset

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        queryset = self.get_queryset()
        paginator = Paginator(queryset, self.paginate_by)
        page = self.request.GET.get('page')

        try:
            page_obj = paginator.get_page(page)
        except PageNotAnInteger:
            page_obj = paginator.get_page(1)
        except EmptyPage:
            page_obj = paginator.get_page(paginator.num_pages)

        context['page_obj'] = page_obj
        context['is_paginated'] = paginator.num_pages > 1
        context['flowruns'] = page_obj.object_list
        context['wsuuid'] = self.workspace_id  # Pass workspace_id for context
        context['flowuuid'] = self.flow_id
        if self.request.GET.get('flowpage') == None:
            context['flowpage'] = '1'
        else:
            context['flowpage'] = self.request.GET.get('flowpage')
        if self.request.GET.get('page') == None:
            context['flowrunpage'] = '1'
        else:   
            context['flowrunpage'] = self.request.GET.get('page')
        
        
        # Calculate dynamic pagination range
        current_page = page_obj.number
        total_pages = paginator.num_pages

        if total_pages <= 10:
            page_range = range(1, total_pages + 1)
        else:
            start = max(current_page - 2, 1)
            end = min(current_page + 2, total_pages)
            page_range = list(range(start, end + 1))

            if start > 2:
                page_range = [1, 2, '...'] + page_range
            if end < total_pages - 1:
                page_range = page_range + ['...', total_pages - 1, total_pages]

        context['page_range'] = page_range
        return context

class FlowRunDetailView(DetailView):
    model = FlowRun
    template_name = 'rapidpro_app/flowrun_detail.html'
    context_object_name = 'flowrun'
    
    def get_context_data(self, **kwargs):
        workspace_id = self.request.GET.get('workspace_id')
        self.workspace_id = workspace_id  # Store for context
        flow_id = self.request.GET.get('flow_id')
        self.flow_id = flow_id  # Store for context
        context = super().get_context_data(**kwargs)
        context['wsuuid'] = self.workspace_id  # Pass workspace_id for context
        context['flowuuid'] = self.flow_id
        context['qa_list'] = self.object.get_questions_and_answers()
        if self.request.GET.get('flowrunpage') == None:
            context['flowrunpage'] = '1'
        else:
            context['flowrunpage'] = self.request.GET.get('flowrunpage')
        if self.request.GET.get('flowpage') == None:
            context['flowpage'] = '1'
        else:
            context['flowpage'] = self.request.GET.get('flowpage')
        return context        
        

def reload_page_view(request):
        return render(request, 'rapidpro_app/dashboard.html')


# Global progress status
progress_status = {"stage": "", "progress": 0}

def sync_data(request):
    if request.method == 'POST':
        # Reset progress status
        global progress_status
        progress_status = {"stage": "Starting sync ...", "progress": 1}
        
        tokens = APIToken.objects.all()
        if not tokens.exists():
            progress_status = {"stage": "No API tokens available.", "progress": 0}
            return JsonResponse({"error": "No API tokens available."}, status=400)
        try:
            for token in tokens:
            
                # Process the data...
                
                progress_status = {"stage": "Setting API Connection ...", "progress": 10}
                service = RapidProService(token.token)
                progress_status = {"stage": "API Endpoint Reachable ...", "progress": 20}
                progress_status = {"stage": "Syncing Workspaces ...", "progress": 30}
                service.sync_workspaces()
                progress_status = {"stage": "Syncing Channels ...", "progress": 40}
                service.sync_channels()
                progress_status = {"stage": "Syncing Flows ...", "progress": 50}
                service.sync_flows()
                progress_status = {"stage": "Syncing Contacts ...", "progress": 60}
                service.sync_contacts()
                progress_status = {"stage": "Syncing Messages ...", "progress": 70}
                service.sync_flow_runs()
                progress_status = {"stage": "Sync completed!", "progress": 100}
                
                
            return JsonResponse({"message": "Sync completed successfully!"})
             
        except Exception as e:
            return JsonResponse({"error": str(e)}, status=500)
    
        
    return JsonResponse({"error": "Invalid request method."}, status=400)
    

def get_progress(request):
    return JsonResponse(progress_status)


def get_graph():
    """
    Converts a matplotlib figure to a base64-encoded string for rendering in HTML.
    """
    buffer = io.BytesIO()
    plt.savefig(buffer, format='png', bbox_inches='tight')
    buffer.seek(0)
    image_png = buffer.getvalue()
    buffer.close()
    plt.close('all')
    return base64.b64encode(image_png).decode('utf-8')

def dashboard(request):
    channel_counts_by_workspace = Channel.objects.values('wsname').annotate(count=Count('id'))
    flow_counts_by_workspace = Flow.objects.values('wsname').annotate(count=Count('id'))
    flowrun_status_counts = FlowRun.objects.values('exit_type').annotate(count=Count('id'))
    flow_run_counts_by_flow = FlowRun.objects.values('flowname').annotate(count=Count('id'))

    # Generate charts
    charts = []

    # Chart 2: Pie chart of Channels count by Workspace
    if channel_counts_by_workspace:
        plt.figure(figsize=(10, 6))
        workspaces = [item['wsname'] for item in channel_counts_by_workspace]
        counts = [item['count'] for item in channel_counts_by_workspace]
        plt.pie(counts, labels=workspaces, autopct='%1.1f%%')
        plt.title('Channels by Workspace')
        charts.append({"title": "Channels by Workspace", "image": get_graph(), "alt": "Pie Chart"})

    # Chart 2: Bar chart of Flows by Workspace
    if flow_counts_by_workspace:
        plt.figure(figsize=(10, 6))
        workspaces = [item['wsname'] for item in flow_counts_by_workspace]
        counts = [item['count'] for item in flow_counts_by_workspace]
        plt.bar(workspaces, counts)
        plt.title('Flows by Workspace')
        plt.xticks(rotation=45)
        charts.append({"title": "Flows by Workspace", "image": get_graph(), "alt": "Bar Chart"})

    # Chart 3: Pie chart of Flow Run Status
    if flowrun_status_counts:
        plt.figure(figsize=(10, 6))
        statuses = [item['exit_type'] for item in flowrun_status_counts]
        counts = [item['count'] for item in flowrun_status_counts]
        plt.pie(counts, labels=statuses, autopct='%1.1f%%')
        plt.title('Flow Run Status Distribution')
        charts.append({"title": "Flow Run Status Distribution", "image": get_graph(), "alt": "Pie Chart"})

    # Chart 4: Bar chart of Flow Runs by Flow
    if flow_run_counts_by_flow:
        plt.figure(figsize=(10, 6))
        flows = [item['flowname'] for item in flow_run_counts_by_flow]
        counts = [item['count'] for item in flow_run_counts_by_flow]
        plt.bar(flows, counts)
        plt.title('Flow Runs by Flow')
        plt.xticks(rotation=45)
        charts.append({"title": "Flow Runs by Flow", "image": get_graph(), "alt": "Bar Chart"})

    # Chart 5: Line chart of Flow Runs Over Time
    flow_run_dates = FlowRun.objects.annotate(date=F('created_on__date')).values('date').annotate(count=Count('id')).order_by('date')
    if flow_run_dates:
        plt.figure(figsize=(10, 6))
        dates = [item['date'] for item in flow_run_dates]
        counts = [item['count'] for item in flow_run_dates]
        plt.plot(dates, counts, marker='o')
        plt.title('Flow Runs Over Time')
        plt.xticks(rotation=45)
        charts.append({"title": "Flow Runs Over Time", "image": get_graph(), "alt": "Line Chart"})

    # Chart 6: Pie chart of Flows by Run Count
    flows_by_run_count = Flow.objects.annotate(run_count=F('runs')).order_by('-run_count')[:5]
    if flows_by_run_count:
        plt.figure(figsize=(10, 6))
        flow_names = [flow.name for flow in flows_by_run_count]
        run_counts = [flow.run_count for flow in flows_by_run_count]
        plt.pie(run_counts, labels=flow_names, autopct='%1.1f%%')
        plt.title('Top Flows by Run Count')
        charts.append({"title": "Top Flows by Run Count", "image": get_graph(), "alt": "Pie Chart"})

    
    # Context for rendering the dashboard
    
    has_tokens = APIToken.objects.exists()
    # Other context data...
    
        
    context = {
        'stats': [
            {"label": "Workspaces", "count": Workspace.objects.count(), "icon": "fa-briefcase", "url": "workspaces"},
            {"label": "Contacts", "count": Contact.objects.count(), "icon": "fa-users", "url": "contacts"},
            {"label": "Channels", "count": Channel.objects.count(), "icon": "fa-broadcast-tower", "url": "channels"},
            {"label": "Flows", "count": Flow.objects.count(), "icon": "fa-project-diagram", "url": "flows"},
            {"label": "Flow Chats", "count": FlowRun.objects.count(), "icon": "fa-comments", "url": "flowruns"},
            {"label": "System Users", "count": User.objects.count(), "icon": "fa-user", "url": "profile"},
        ],
        'charts': charts,
        'has_tokens': has_tokens,
    }
    return render(request, 'rapidpro_app/dashboard.html', context)


from django.shortcuts import render, redirect
from django.contrib.auth import authenticate, login, logout
from django.contrib import messages
from django.contrib.auth.forms import AuthenticationForm

def user_login(request):
    if request.method == 'POST':
        form = AuthenticationForm(request, data=request.POST)
        if form.is_valid():
            user = form.get_user()
            login(request, user)
            messages.success(request, "You have successfully logged in.")
            return redirect('dashboard')  # Redirect to your desired page
        else:
            messages.error(request, "Invalid username or password.")
    else:
        form = AuthenticationForm()

    context = {
        'form': form,
    }
    return render(request, 'rapidpro_app/login.html', context)

def user_logout(request):
    logout(request)
    messages.success(request, "You have been logged out.")
    return redirect("dashboard")  # Replace with your login URL name



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
                #user.set_password(password)
                #user.save()
                print(user.password)
                messages.success(request, "Account created successfully! Please log in.")
                return redirect('login')
        else:
            messages.error(request, "Passwords do not match.")
    return render(request, 'rapidpro_app/register.html')


@login_required
def profile(request):
    if request.method == "POST":
        user = request.user
        user.first_name = request.POST.get("first_name")
        user.last_name = request.POST.get("last_name")
        user.email = request.POST.get("email")
        user.save()
        messages.success(request, "User profile updated successfully!")
        return redirect("profile")
    return render(request, "rapidpro_app/profile.html")


# REST API CODE Using Serializers  --------------------------------------------------------


class WorkspaceListAPIView(APIView):
    def get(self, request, *args, **kwargs):
        workspaces = Workspace.objects.all()
        serializer = WorkspaceSerializer(workspaces, many=True)
        return Response(serializer.data)


class ContactListAPIView(APIView):
    def get(self, request, *args, **kwargs):
        contacts = Contact.objects.all()
        serializer = ContactSerializer(contacts, many=True)
        return Response(serializer.data)


class ChannelListAPIView(APIView):
    def get(self, request, *args, **kwargs):
        channels = Channel.objects.all()
        serializer = ChannelSerializer(channels, many=True)
        return Response(serializer.data)


class FlowListAPIView(APIView):
    def get(self, request, *args, **kwargs):
        flows = Flow.objects.all()
        serializer = FlowSerializer(flows, many=True)
        return Response(serializer.data)


class FlowRunListAPIView(APIView):
    def get(self, request, *args, **kwargs):
        flowruns = FlowRun.objects.all()
        serializer = FlowRunSerializer(flowruns, many=True)
        return Response(serializer.data)
