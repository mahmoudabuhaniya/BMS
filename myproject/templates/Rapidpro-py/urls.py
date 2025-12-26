from django.urls import path
from . import views
from django.contrib.auth import views as auth_views
from .views import WorkspaceListAPIView, ContactListAPIView, ChannelListAPIView, FlowListAPIView, FlowRunListAPIView
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView


urlpatterns = [
    path('', views.dashboard, name='dashboard'),
    path('workspaces/', views.WorkspaceListView.as_view(), name='workspace_list'),
    path('channels/', views.ChannelListView.as_view(), name='channel_list'),
    path('flows/', views.FlowListView.as_view(), name='flow_list'),
    path('contacts/', views.ContactListView.as_view(), name='contact_list'),
    path('flowruns/', views.FlowRunListView.as_view(), name='flowrun_list'),
    path('sync/', views.sync_data, name='sync_data'),
    path('flowruns/<str:pk>/', views.FlowRunDetailView.as_view(), name='flowrun_detail'),
    path('get-progress/', views.get_progress, name='get_progress'),
    path('manage-tokens/', views.manage_tokens, name='manage_tokens'),
    path('delete-token/<int:pk>/', views.delete_token, name='delete_token'), 
    path('login/', views.user_login, name='login'),
    path('logout/', views.user_logout, name='logout'),
    path('register/', views.user_register, name='register'),
    path('password_change/', auth_views.PasswordChangeView.as_view(template_name='rapidpro_app/password_change.html'), name='password_change'),
    path('profile/', views.profile, name='profile'),  # Example: Add a view for the user's profile
    path('password_reset/', auth_views.PasswordResetView.as_view(template_name='registration/password_reset.html'), name='password_reset'),
    path('password_reset_done/', auth_views.PasswordResetDoneView.as_view(template_name='registration/password_reset_done.html'), name='password_reset_done'),
    path('reset/<uidb64>/<token>/', auth_views.PasswordResetConfirmView.as_view(template_name='registration/password_reset_confirm.html'), name='password_reset_confirm'),
    path('reset/done/', auth_views.PasswordResetCompleteView.as_view(template_name='registration/password_reset_complete.html'), name='password_reset_complete'),
    path('api/workspaces/', WorkspaceListAPIView.as_view(), name='workspace-list'),
    path('api/contacts/', ContactListAPIView.as_view(), name='contact-list'),
    path('api/channels/', ChannelListAPIView.as_view(), name='channel-list'),
    path('api/flows/', FlowListAPIView.as_view(), name='flow-list'),
    path('api/flowruns/', FlowRunListAPIView.as_view(), name='flowrun-list'),
    path('api/token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('api/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    
]