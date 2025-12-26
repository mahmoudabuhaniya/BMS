from django.contrib import admin
from .models import Beneficiary, APIToken

@admin.register(Beneficiary)
class BeneficiaryAdmin(admin.ModelAdmin):
    list_display = ('record_id', 'InForm_ID', 'Name', 'Date_of_Birth', 'created_at','Sector')  # ✅ Show key fields
    search_fields = ('record_id', 'Name', 'Sector')  # ✅ Enable search by ID or name
    list_filter = ('created_at',)  # ✅ Filter by sync date
    ordering = ('-created_at',)  # ✅ Newest first
    list_per_page = 200  # ✅ Paginate in admin view

    def save_model(self, request, obj, form, change):
        # Set created_by only on creation
        if not obj.pk:
            obj.created_by = request.user
        super().save_model(request, obj, form, change)


    def get_queryset(self, request):
        qs = super().get_queryset(request)

        # Admins/Managers see everything
        if request.user.is_superuser or request.user.groups.filter(name__in=["Manager", "Admin"]).exists():
            return qs

        # Normal staff only see their own records
        return qs.filter(created_by=request.user)
    
    def has_change_permission(self, request, obj=None):
        if obj is None:
            return True

        if request.user.is_superuser or request.user.groups.filter(name__in=["Manager", "Admin"]).exists():
            return True

        return obj.created_by == request.user
    




@admin.register(APIToken)
class APIToken(admin.ModelAdmin):
    list_display = ('id','section', 'form_id', 'token', 'last_used', 'created_at')
    list_filter = ('section', 'form_id', 'token')
    search_fields = ('token',)
    readonly_fields = ('id',)


 