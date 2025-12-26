from django.utils import timezone
from django.db import models
from django.contrib.auth.models import User


class Supply(models.Model):
    section = models.CharField(max_length=255, null=True, blank=True)
    ip_name = models.CharField(max_length=255, null=True, blank=True)
    supply_type = models.CharField(max_length=255)
    eligibility_period = models.CharField(max_length=500)
    distribution_date = models.DateField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    created_by = models.CharField(
        max_length=150,
        null=True,
        blank=True,
        editable=False)
    updated_by = models.CharField(
        max_length=150,
        null=True,
        blank=True,
        editable=False)  

    def __str__(self):
        return f"{self.supply_type} ({self.eligibility_period})"

    

class APIToken(models.Model):
    section = models.CharField(null=True, max_length=255)  
    IP = models.CharField(null=True, max_length=255)
    form_id = models.CharField(max_length=255)  
    token = models.CharField(max_length=500)  # The token itself
    last_used = models.DateTimeField(null=True, blank=True)  # Optional: To track when the token was last used
    created_at = models.DateTimeField(auto_now_add=True)  # To track when the token was created

    def __str__(self):
        return f"{self.form_id} - {self.token[:10]}..."  # Display the name and a part of the token

class BeneficiaryManager(models.Manager):
    def get_queryset(self):
        # Exclude records where Deleted == 'True'
        return super().get_queryset().exclude(Deleted=True)
    
class BenDeletedManager(models.Manager):
    def get_queryset(self):
        # Exclude records where Deleted == 'True'
        return super().get_queryset().filter(Deleted=True)
        
class Beneficiary(models.Model):
    
    record_id = models.CharField(max_length=255, null=True, blank=True)
    InForm_ID = models.CharField(max_length=255, null=True, blank=True)
    InstanceID = models.CharField(max_length=255, null=True, blank=True)
    IP_Name = models.CharField(max_length=255, null=True, blank=True)
    Sector = models.CharField(max_length=255, null=True, blank=True)
    Indicator = models.CharField(max_length=255, null=True, blank=True)
    Date = models.DateField(null=True, blank=True)
    Name = models.CharField(max_length=255, null=True, blank=True)
    ID_Number = models.CharField(max_length=100, null=True, blank=True)
    Parent_ID = models.CharField(max_length=100, null=True, blank=True)
    Spouse_ID = models.CharField(max_length=100, null=True, blank=True)
    Phone_Number = models.CharField(max_length=100, null=True, blank=True)
    Date_of_Birth = models.DateField(null=True, blank=True)
    Age = models.CharField(max_length=255, null=True, blank=True)
    Gender = models.CharField(max_length=255, null=True, blank=True)
    Governorate = models.CharField(max_length=255, null=True, blank=True)
    Municipality = models.CharField(max_length=255, null=True, blank=True)
    Neighborhood = models.CharField(max_length=255, null=True, blank=True)
    Site_Name = models.CharField(max_length=255, null=True, blank=True)
    Disability_Status = models.CharField(max_length=255, null=True, blank=True)
    updated_at = models.DateTimeField(auto_now=True)
    updated_by = models.CharField(
        max_length=150,
        null=True,
        blank=True,
        editable=False)
    created_at = models.DateTimeField(auto_now_add=True)
    created_by = models.CharField(
        max_length=150,
        null=True,
        blank=True,
        editable=False)
    Submission_Time = models.DateTimeField(null=True, blank=True)
    Deleted = models.BooleanField(default=False, null=True, blank=True)
    deleted_at = models.DateTimeField(null=True, blank=True)
    deleted_by = models.CharField(max_length=255, null=True, blank=True)
    undeleted_at = models.DateTimeField(null=True, blank=True)
    undeleted_by = models.CharField(max_length=255, null=True, blank=True)
    Household_ID = models.CharField(max_length=50, null=True, blank=True)
    synced = models.CharField(max_length=255, null=True, blank=True)
    Supply_Type = models.CharField(max_length=255, null=True, blank=True)
    Benefit_Date = models.DateField(null=True, blank=True)
    Marital_Status = models.CharField(max_length=255, null=True, blank=True)
    HH_Members = models.CharField(max_length=255, null=True, blank=True)
    Eligiblity = models.BooleanField(default=False, null=True, blank=True)
    supply_batch_id = models.UUIDField(null=True, blank=True, db_index=True)

    # override tracking
    Override_Eligibility = models.BooleanField(default=False)
    Override_By = models.CharField(max_length=255, null=True, blank=True)
    Override_At = models.DateTimeField(null=True, blank=True)

    supply = models.ForeignKey(
        Supply,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name='beneficiaries'
    )

    class Meta:
        permissions = [
            ("import_beneficiary", "Can import beneficiary"),
            ("export_beneficiary", "Can export beneficiary"),
        ]

    objects = BeneficiaryManager()  # Custom manager to exclude soft-deleted records
    all_objects = models.Manager()  # Default manager to access all records including deleted ones
    deleted_objects = BenDeletedManager() # Manager to access only deleted records

    def __str__(self):
        return f"{self.Name} ({self.ID_Number})"
    
    def soft_delete(self):
        self.Deleted = True
        self.deleted_at = timezone.now()
        self.save(update_fields=["Deleted", "deleted_at"])
    

