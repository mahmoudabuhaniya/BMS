from rest_framework import serializers
from .models import Workspace, Channel, Flow, Contact, FlowRun


class WorkspaceSerializer(serializers.ModelSerializer):
    class Meta:
        model = Workspace
        fields = '__all__'  # Or specify specific fields to expose

class ContactSerializer(serializers.ModelSerializer):
    class Meta:
        model = Contact
        fields = '__all__'  # Or specify specific fields to expose
        
class ChannelSerializer(serializers.ModelSerializer):
    class Meta:
        model = Channel
        fields = '__all__'  # Or specify specific fields to expose
        
class FlowSerializer(serializers.ModelSerializer):
    class Meta:
        model = Flow
        fields = '__all__'  # Or specify specific fields to expose
        
class FlowRunSerializer(serializers.ModelSerializer):
    class Meta:
        model = FlowRun
        fields = '__all__'  # Or specify specific fields to expose
