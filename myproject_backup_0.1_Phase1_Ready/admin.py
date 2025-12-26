from django.contrib import admin
from .models import Beneficiary, APIToken

@admin.register(Beneficiary)
class BeneficiaryAdmin(admin.ModelAdmin):
    list_display = ('record_id', 'InForm_ID', 'Name', 'Date_of_Birth', 'created_at','Sector')  # ✅ Show key fields
    search_fields = ('record_id', 'Name', 'Sector')  # ✅ Enable search by ID or name
    list_filter = ('created_at',)  # ✅ Filter by sync date
    ordering = ('-created_at',)  # ✅ Newest first
    list_per_page = 200  # ✅ Paginate in admin view

@admin.register(APIToken)
class APIToken(admin.ModelAdmin):
    list_display = ('id','section', 'form_id', 'token', 'last_used', 'created_at')
    list_filter = ('section', 'form_id', 'token')
    search_fields = ('token',)
    readonly_fields = ('id',)