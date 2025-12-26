from django.contrib import admin
from django.urls import include, path
from . import views
from django.contrib.auth import views as auth_views
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView
from rest_framework.routers import DefaultRouter
from .views import BeneficiaryViewSet
from .views import current_user_info

router = DefaultRouter()
router.register(r'beneficiaries', BeneficiaryViewSet, basename='beneficiary')

urlpatterns = [
    path('', views.home, name='home'),
    path('admin/', admin.site.urls, name='admin'),
    path('inform/', views.inform_data_view, name='inform_data'),
    path('inform/delete/<int:pk>/', views.delete_inform, name='delete_inform'),
    path('sync/', views.sync_data, name='sync_data'),
    path('manage-tokens/', views.manage_tokens, name='manage_tokens'),
    path('delete-token/<int:pk>/', views.delete_token, name='delete_token'), 
    path('progress/', views.get_progress, name='get_progress'),  # New endpoint for progress
    path('login/', views.user_login, name='login'),
    path('logout/', views.user_logout, name='logout'),
    path('register/', views.user_register, name='register'),
    path('password_change/', views.password_change, name='password_change'),
    path('profile/', views.profile, name='profile'),  # Example: Add a view for the user's profile
    path('password_reset/', auth_views.PasswordResetView.as_view(template_name='myproject/password_reset.html'), name='password_reset'),
    path('password_change_done/', auth_views.PasswordResetDoneView.as_view(template_name='myproject/password_change_done.html'), name='password_reset_done'),
    path('reset/<uidb64>/<token>/', auth_views.PasswordResetConfirmView.as_view(template_name='myproject/password_reset_confirm.html'), name='password_reset_confirm'),
    path('reset/done/', auth_views.PasswordResetCompleteView.as_view(template_name='myproject/password_reset_complete.html'), name='password_reset_complete'),
    path('duplicates/', views.find_duplicates, name='find_duplicates'),
    path('duplicates/delete/<int:pk>/', views.delete_duplicate, name='delete_duplicate'),
    path('beneficiary/<int:pk>/', views.beneficiary_details, name='beneficiary_details'),
    path('household/<str:household_id>/', views.household_details, name='household_details'),
    path("deleted/", views.deleted_beneficiaries, name="deleted_beneficiaries"),
    path("assign-households/", views.assign_households_view, name="assign_households"),
    path("beneficiary/add/", views.beneficiary_add, name="beneficiary_add"),
    path("autocomplete/", views.autocomplete, name="autocomplete"),
    path("beneficiaries/check-duplicate/<str:id_number>/", views.check_duplicate, name="check_duplicate"),
    
    # --- Supply ---
    path('supplies/', views.supply_list, name='supply_list'),
    path('supplies/add/', views.supply_add, name='supply_add'),
    path('supplies/<int:pk>/edit/', views.supply_update, name='supply_update'),
    path('supplies/<int:pk>/delete/', views.supply_delete, name='supply_delete'),
    path('supplies/dashboard/', views.supply_dashboard, name='supply_dashboard'),
    path(
    'supplies/<str:supply_type>/beneficiaries/',
    views.supply_beneficiaries,
    name='supply_beneficiaries'
    ),
    path(
    "supplies/dashboard/export/",
    views.export_supply_dashboard_excel,
    name="export_supply_dashboard_excel"
    ),

    path(
        "supplies/<str:supply_type>/export/",
        views.export_supply_beneficiaries_excel,
        name="export_supply_beneficiaries_excel"
    ),

    #=================BULK SUPPLY IMPORT============================================

    # ================= BULK SUPPLY IMPORT =================

    path(
        "supplies/bulk-import/",
        views.bulk_supply_import_page,
        name="bulk_supply_import"
    ),

    path(
        "supplies/bulk-import/review/",
        views.bulk_supply_review,
        name="bulk_supply_review"
    ),

    path(
        "supplies/bulk-import/preview/",
        views.bulk_supply_preview,
        name="bulk_supply_preview"
    ),

    path(
        "supplies/bulk-import/override/",
        views.bulk_supply_override_eligibility,
        name="bulk_supply_override"
    ),

    path(
        "supplies/bulk-import/delete-row/",
        views.bulk_supply_delete_preview_row,
        name="bulk_supply_delete_preview_row"
    ),

    path(
        "supplies/bulk-import/commit/",
        views.bulk_supply_import_commit,
        name="bulk_supply_import_commit"
    ),

    path(
        "supplies/bulk-import/done/<uuid:batch_id>/",
        views.bulk_supply_done,
        name="bulk_supply_done"
    ),

    path(
        "supplies/bulk-import/export/<uuid:batch_id>/",
        views.bulk_supply_export_excel,
        name="bulk_supply_export_excel"
    ),

    # myproject/urls.py

    path(
        "supplies/eligibility-check/",
        views.eligibility_check,
        name="eligibility_check"
    ),
    path(
        "supplies/eligibility-search/",
        views.eligibility_search,
        name="eligibility_search"
    ),
    path(
        "supplies/eligibility-submit/",
        views.eligibility_submit,
        name="eligibility_submit"
    ),

    path(
        "supplies/eligibility-evaluate/",
        views.eligibility_evaluate,
        name="eligibility_evaluate"
    ),




    
      
    # JWT endpoints
    path('api/token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('api/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('api/distinct/ip-names/', views.distinct_ip_names),
    path('api/distinct/sectors/', views.distinct_sectors),
    path('api/current-user/', current_user_info, name='current-user-info'),

    # BULK IMPORT Endpoint
    path('bulk-upload/', views.bulk_upload_page, name='bulk_upload_page'),
    path('bulk-upload/start/', views.start_bulk_import, name='start_bulk_import'),
    path('bulk-upload/progress/', views.get_bulk_progress, name='get_bulk_progress'),

    # Include API routes under /api/
    path('api/', include(router.urls)),
    
    # Include audit urls 
    path("audit/", include("audit.urls")),

    # Include Mobile API routes under /mobile/
    path("api/mobile/", include("myproject.api.urls_mobile")),


    ]





