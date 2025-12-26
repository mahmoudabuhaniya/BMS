from rest_framework import serializers
from .models import Beneficiary, APIToken

class BeneficiarySerializer(serializers.ModelSerializer):
    class Meta:
        model = Beneficiary
        fields = ['id', 'record_id', 'InForm_ID' ,'InstanceID' ,'IP_Name' ,'Sector' ,'Indicator' ,'Date' ,'Name' ,'ID_Number' ,'Parent_ID' ,'Spouse_ID' ,'Phone_Number' ,'Date_of_Birth' ,'Age' ,'Gender' ,'Governorate' ,'Municipality' ,'Neighborhood' ,'Site_Name' ,'Disability_Status' ,'created_at' ,'Submission_Time' ,'Deleted' ,'deleted_at' ,'undeleted_at' ,'Household_ID']


class APITokenSerializer(serializers.ModelSerializer):
    class Meta:
        model = APIToken
        fields = ['section' ,'IP' ,'form_id' ,'token' ,'last_used' ,'created_at']