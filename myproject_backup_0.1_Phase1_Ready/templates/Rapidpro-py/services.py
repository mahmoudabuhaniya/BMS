import requests
from django.contrib import messages
from django.conf import settings
from django.utils import timezone
from .models import Workspace, Channel, Flow, Contact, FlowRun
import logging
from django.db.models import Max
from bulk_update_or_create import BulkUpdateOrCreateQuerySet
from django.http import JsonResponse

    

class RapidProService:
   
    
    def __init__(self, TOKEN):
        self.base_url = settings.RAPIDPRO_API_BASE_URL
        self.headers = {
            'Authorization': f'Token {TOKEN}',
            'Content-Type': 'application/json'
        }

    def _make_request(self, endpoint, params=None):
        url = f"{self.base_url}/{endpoint}"
        response = requests.get(url, headers=self.headers, params=params)
        response.raise_for_status()
        
        return response.json()
    
        

    def sync_workspaces(self):
        wsdata = self._make_request("api/v2/workspace.json")
        Workspace.objects.update_or_create(
        uuid=wsdata['uuid'],
        defaults={
            'name': wsdata['name'],
            'timezone': wsdata['timezone'],
            'country': wsdata['country'],
                }
            )
        global wsuuid
        wsuuid=wsdata['uuid']
        global wsname
        wsname=wsdata['name']
        print(f'Workspace Results: Successful!')

    def sync_channels(self):
        last_synced_time = Channel.objects.filter(wsuuid=wsuuid).aggregate(max_modified=Max('last_synced'))['max_modified']
        if not last_synced_time:
            last_synced_time = '2016-01-01T00:00:00.000'
        else:
            last_synced_time = last_synced_time.strftime('%Y-%m-%dT%H:%M:%S.%fZ')
        next_url = f"api/v2/channels.json?modified_after={last_synced_time}&ordering=-created_on"  # Initial endpoint    
        data = self._make_request(next_url)
        for channel_data in data['results']:
            Channel.objects.update_or_create(
                uuid=channel_data['uuid'],
                defaults={
                    'name': channel_data['name'],
                    'address': channel_data['address'],
                    'created_on': channel_data['created_on'],
                    'wsuuid': wsuuid,
                    'wsname': wsname,

                }
            )
        print(f'Channel Results: Successful!')

    def sync_flows(self):
        last_synced_time = Flow.objects.filter(wsuuid=wsuuid).aggregate(max_modified=Max('last_synced'))['max_modified']
        if not last_synced_time:
            last_synced_time = '2016-01-01T00:00:00.000'
        else:
            last_synced_time = last_synced_time.strftime('%Y-%m-%dT%H:%M:%S.%fZ')
        next_url = f"api/v2/flows.json?modified_after={last_synced_time}&ordering=-created_on"  # Initial endpoint    
        data = self._make_request(next_url)
        for flow_data in data['results']:
            Flow.objects.update_or_create(
                uuid=flow_data['uuid'],
                defaults={
                    'name': flow_data['name'],
                    'runs': flow_data['runs']['completed'],
                    'created_on': flow_data['created_on'],
                    'wsuuid': wsuuid,
                    'wsname': wsname,
                    
                }
                
            )
        print(f'Flow Results: Successful!')

    def sync_contacts(self):
        contacts_to_sync = []
        last_synced_time = Contact.objects.filter(wsuuid=wsuuid).aggregate(max_modified=Max('last_synced'))['max_modified']
        if not last_synced_time:
            last_synced_time = '2016-01-01T00:00:00.000'
        else:
            last_synced_time = last_synced_time.strftime('%Y-%m-%dT%H:%M:%S.%fZ')
        next_url = f"api/v2/contacts.json?modified_after={last_synced_time}&ordering=-created_on"  # Initial endpoint
        # Get the last synced time
         
        while next_url:
            data = self._make_request(next_url)  # Fetch data from the current page
            if data['results'][0]['created_on'] < last_synced_time:
                break
            for contact_data in data['results']:
                if contact_data['created_on'] < last_synced_time:
                    break
                contacts_to_sync.append(Contact(
                    uuid=contact_data['uuid'],
                    name= contact_data['name'],
                    language= contact_data['language'],
                    urns= contact_data['urns'],
                    groups= contact_data['groups'],
                    status= contact_data['status'],
                    created_on=contact_data['created_on'],
                    wsuuid= wsuuid,
                    wsname= wsname,
                ))
               
            # Bulk save every 500 records
            if len(contacts_to_sync) >= 500:
                # Bulk create or update
                try:
                    Contact.objects.bulk_update_or_create(
                    contacts_to_sync, 
                    ["name", "language", "urns", "groups", "status", "created_on", "wsuuid", "wsname"], 
                    match_field="uuid"
                    )
                    #print('saved to DB')
                except Exception as e:
                    # Log the exception or print it for debugging
                    print(f"Error syncing data: {e}")
                    return JsonResponse({"status": "error", "message": str(e)}, status=500)
                
                contacts_to_sync = []
            # Update the next_url to fetch the next page, if available
            next_url = data.get('next')  # RapidPro includes 'next' in the response
            if next_url:
                next_url= next_url.removeprefix("https://app.rapidpro.io/")
            else:
                break

        # Final bulk save
        if contacts_to_sync:
            try:
                Contact.objects.bulk_update_or_create(
                    contacts_to_sync, 
                    ["name", "language", "urns", "groups", "status", "created_on", "wsuuid", "wsname"], 
                    match_field="uuid"
                    )
                
            except Exception as e:
                # Log the exception or print it for debugging
                print(f"Error syncing data: {e}")
                return JsonResponse({"status": "error", "message": str(e)}, status=500)
        print(f'Contact Results: Successful!')
    
    
    def sync_flow_runs(self):
        flow_runs_to_sync = []
        last_synced_time = FlowRun.objects.filter(wsuuid=wsuuid).aggregate(max_modified=Max('last_synced'))['max_modified']
        
        if not last_synced_time:
            last_synced_time = '2016-01-01T00:00:00.000'
        else:
            last_synced_time = last_synced_time.strftime('%Y-%m-%dT%H:%M:%S.%fZ')
        next_url = f"api/v2/runs.json?modified_after={last_synced_time}&ordering=-created_on"  # Initial endpoint
        
        # Get the last synced time
         
        while next_url:
            data = self._make_request(next_url)  # Fetch data from the current page
            #print(next_url)
            #print(last_synced_time)
            #print(data)
            #print(data['results'])
            if data['results'][0]['created_on'] < last_synced_time:
                    break
            for run_data in data['results']:
                if run_data['created_on'] < last_synced_time:
                    break
                flow_runs_to_sync.append(FlowRun(
                    uid=run_data['id'],
                    uuid=run_data['uuid'],
                    flowuuid=run_data['flow']['uuid'],
                    wsuuid=wsuuid,
                    wsname=wsname,
                    flowname=run_data['flow']['name'],
                    contact=run_data['contact']['uuid'],
                    contactname=run_data['contact']['name'],
                    urn=run_data['contact'].get('urn'),
                    exit_type=run_data['exit_type'],
                    created_on=run_data['created_on'],
                    modified_on=run_data['modified_on'],
                    exited_on=run_data.get('exited_on'),
                    values=run_data.get('values', {}),
                    results=run_data.get('results', {}),
                ))
                

            # Bulk save every 500 records
            if len(flow_runs_to_sync) >= 500:
                # Bulk create or update
                FlowRun.objects.bulk_update_or_create(
                flow_runs_to_sync, 
                ["uuid", "flowuuid", "flowname", "wsuuid", "wsname", "contact", "contactname", "urn", 
                 "exit_type", "created_on", "modified_on", "exited_on", "values", "results"], 
                match_field="uid"
                )
                flow_runs_to_sync = []

            # Update the next_url to fetch the next page, if available
            next_url = data.get('next')  # RapidPro includes 'next' in the response
            if next_url:
                next_url= next_url.removeprefix("https://app.rapidpro.io/")
            else:
                break

        # Final bulk save
        if flow_runs_to_sync:
            FlowRun.objects.bulk_update_or_create(
                flow_runs_to_sync, 
                ["uuid", "flowuuid", "flowname", "wsuuid", "wsname", "contact", "contactname", "urn", 
                 "exit_type", "created_on", "modified_on", "exited_on", "values", "results"], 
                match_field="uid"
                )
        print(f'FlowRuns Results: Successful!')
        

    
