from django.urls import path
from .views import audit_log_view, export_audit_csv, export_audit_excel, export_audit_pdf, delete_log, audit_detail

urlpatterns = [
    path("logs/", audit_log_view, name="audit_logs"),
    path("logs/export/csv/", export_audit_csv, name="audit_export_csv"),
    path("logs/export/excel/", export_audit_excel, name="audit_export_excel"),
    path("logs/export/pdf/", export_audit_pdf, name="audit_export_pdf"),
    path("logs/delete/<int:pk>/", delete_log, name="audit_delete"),
    path("logs/<int:pk>/detail/", audit_detail, name="audit_detail"),
]
