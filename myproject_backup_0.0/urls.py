from django.contrib import admin
from django.urls import path
from . import views
from django.contrib.auth import views as auth_views

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
    #path("check_duplicate/", views.check_duplicate, name="check_duplicate"),


]

