from django.db import models
from django.utils import timezone
from bulk_update_or_create import BulkUpdateOrCreateQuerySet

class APIToken(models.Model):
    name = models.CharField(max_length=255)  # Optional: Name or description of the token
    token = models.CharField(max_length=500)  # The token itself
    last_used = models.DateTimeField(null=True, blank=True)  # Optional: To track when the token was last used
    created_at = models.DateTimeField(auto_now_add=True)  # To track when the token was created

    def __str__(self):
        return f"{self.name} - {self.token[:10]}..."  # Display the name and a part of the token


class Workspace(models.Model):
    uuid = models.CharField(max_length=255, unique=True)
    name = models.CharField(max_length=255)
    country = models.CharField(max_length=255, null=True)
    timezone = models.CharField(max_length=255, null=True)
    last_synced = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.name

class Channel(models.Model):
    uuid = models.CharField(max_length=255, unique=True)
    name = models.CharField(max_length=255)
    address = models.CharField(max_length=255)
    wsuuid = models.CharField(max_length=255, null=True)
    wsname = models.CharField(max_length=255, null=True)
    created_on = models.DateTimeField(null=True)
    last_synced = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.name} ({self.address})"

class Flow(models.Model):
    uuid = models.CharField(max_length=255, unique=True)
    name = models.CharField(max_length=255)
    wsuuid = models.CharField(max_length=255, null=True)
    wsname = models.CharField(max_length=255, null=True)
    runs = models.IntegerField(null=True)
    created_on = models.DateTimeField(null=True)
    last_synced = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.name

class Contact(models.Model):
    uid = models.CharField(max_length=50, null=True)
    uuid = models.CharField(max_length=255, unique=True)
    name = models.CharField(max_length=255, null=True)
    wsuuid = models.CharField(max_length=255, null=True)
    wsname = models.CharField(max_length=255, null=True)
    language = models.CharField(max_length=10, null=True)
    status = models.CharField(max_length=20, null=True)
    urns = models.JSONField(default=list, null=True)
    groups = models.JSONField(default=list, null=True)
    created_on = models.DateTimeField(null=True)
    last_synced = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.name or self.uuid
    
    # Use BulkUpdateOrCreateQuerySet for the manager
    objects = BulkUpdateOrCreateQuerySet.as_manager()



class FlowRun(models.Model):
    uid = models.CharField(max_length=50, null=True)
    uuid = models.CharField(max_length=255, unique=True)
    wsuuid = models.CharField(max_length=100, null=True)
    wsname = models.CharField(max_length=200, null=True)
    flowuuid = models.CharField(max_length=100, null=True)
    flowname = models.CharField(max_length=50, null=True)
    contact = models.CharField(max_length=100, null=True)
    contactname = models.CharField(max_length=100, null=True)
    urn = models.CharField(max_length=100, null=True)
    exit_type = models.CharField(max_length=50, null=True)
    created_on = models.DateTimeField()
    modified_on = models.DateTimeField()
    exited_on = models.DateTimeField(null=True)
    values = models.JSONField(default=dict)
    path = models.JSONField(default=list)
    results = models.JSONField(default=dict)
    last_synced = models.DateTimeField(auto_now=True)
    
    def get_questions_and_answers(self):
        """
        Returns a structured list of questions and answers from the flow run
        """
        qa_list = []
        
        # Process values dictionary which contains the questions and answers
        for key, value in self.values.items():
            qa_item = {
                'question_id': key,
                'question': value.get('name', ''),  # The question text/name
                'answer': value.get('value', ''),   # The answer value
                'category': value.get('category', ''),  # The category of the answer
                'time': value.get('time', ''),      # When the question was answered
                'input': value.get('input', ''),    # The raw input from the contact
                'node': value.get('node', '')       # The node UUID in the flow
            }
            qa_list.append(qa_item)

        # Sort by time if available
        qa_list.sort(key=lambda x: x['time'] if x['time'] else '1970-01-01')
        return qa_list

    def __str__(self):
        return f"{self.flowname} - {self.contactname}"
    
    # Use BulkUpdateOrCreateQuerySet for the manager
    objects = BulkUpdateOrCreateQuerySet.as_manager()
