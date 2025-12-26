
from django.shortcuts import get_object_or_404, render, redirect
from django.db.models import Q
from django.core.paginator import Paginator
from django.utils import timezone
from django.http import HttpResponse
import csv
import openpyxl
from openpyxl import Workbook, load_workbook  # used to read Excel files
from openpyxl.styles import Font
from .models import AuditLog

from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet
from reportlab.lib import colors
import json
from django.contrib.auth import authenticate, login, logout
from django.contrib.auth.forms import AuthenticationForm
from django.contrib.auth.decorators import login_required
from django.contrib.auth.models import User
from django.contrib.auth import update_session_auth_hash

# -------------------------
# Log user actions
# -------------------------
def log_user_action(request, action, model_name=None, record_id=None, changes=None, description=None):
    user = request.user if request.user.is_authenticated else None
    AuditLog.objects.create(
        user=user,
        action=action,
        model_name=model_name,
        record_id=record_id,
        changes=changes or {},
        description=description,
        timestamp=timezone.now()
    )

# -------------------------
# View audit logs
# -------------------------

from django.shortcuts import render
from django.db.models import Q
from django.core.paginator import Paginator
from .models import AuditLog
from django.contrib.auth.models import User

@login_required
def audit_log_view(request):
    logs = AuditLog.objects.all().order_by("-timestamp")

    # --- Filters ---
    user_id = request.GET.get("user")
    action = request.GET.get("action")
    date_from = request.GET.get("date_from")
    date_to = request.GET.get("date_to")

    if user_id:
        logs = logs.filter(user_id=user_id)
    if action:
        logs = logs.filter(action__iexact=action)
    if date_from:
        logs = logs.filter(timestamp__date__gte=date_from)
    if date_to:
        logs = logs.filter(timestamp__date__lte=date_to)

    # --- Pagination ---
    paginator = Paginator(logs, 20)
    page = request.GET.get("page")
    page_obj = paginator.get_page(page)

    # --- Users list for dropdown ---
    users = User.objects.filter(id__in=AuditLog.objects.values_list('user_id', flat=True).distinct())

    # --- Actions list ---
    actions = ["create", "update", "delete", "login", "logout"]

    context = {
        "page_obj": page_obj,
        "logs": page_obj,
        "users": users,
        "actions": actions,
        "request": request,  # needed for selected in template
    }
    return render(request, "audit_log.html", context)


# -------------------------
# Export CSV
# -------------------------
@login_required
def export_audit_csv(request):
    response = HttpResponse(content_type="text/csv")
    response["Content-Disposition"] = "attachment; filename=audit_logs.csv"
    writer = csv.writer(response)
    writer.writerow(["Timestamp", "User", "Action", "Model", "Object ID", "IP Address", "Changes"])

    logs = AuditLog.objects.all().order_by("-timestamp")
    for log in logs:
        writer.writerow([
            log.timestamp,
            log.user.username if log.user else "Anonymous",
            log.action,
            log.model_name,
            log.record_id,
            log.ip_address,
            log.changes,
            log.description,
        ])
    return response

# -------------------------
# Export Excel
# -------------------------
def export_audit_excel(request):
    wb = openpyxl.Workbook()
    ws = wb.active
    ws.title = "Audit Logs"
    ws.append(["Timestamp", "User", "Action", "Model", "Object ID", "IP Address", "Changes"])

    logs = AuditLog.objects.all().order_by("-timestamp")
    for log in logs:
        ws.append([
            str(log.timestamp),
            log.user.username if log.user else "Anonymous",
            log.action,
            log.model_name,
            log.record_id,
            log.ip_address,
            str(log.changes),
            log.description,
        ])

    response = HttpResponse(content_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
    response["Content-Disposition"] = "attachment; filename=audit_logs.xlsx"
    wb.save(response)
    return response

# -------------------------
# Export PDF
# -------------------------
@login_required
def export_audit_pdf(request):
    from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, PageBreak
    from reportlab.lib import colors
    from reportlab.lib.pagesizes import landscape, letter
    from reportlab.lib.styles import getSampleStyleSheet
    from io import BytesIO

    buffer = BytesIO()
    doc = SimpleDocTemplate(buffer, pagesize=landscape(letter))

    styles = getSampleStyleSheet()
    body_style = styles["BodyText"]
    body_style.wordWrap = 'CJK'  # enables proper wrapping
    body_style.fontSize = 8

    # ----- HEADER -----
    data = [
        ["Timestamp", "User", "Action", "Model", "Object ID", "IP Address", "Changes"]
    ]

    logs = AuditLog.objects.all().order_by("-timestamp")

    for log in logs:

        # Wrap long fields using Paragraph
        timestamp = Paragraph(str(log.timestamp), body_style)
        user = Paragraph(log.user.username if log.user else "Anonymous", body_style)
        action = Paragraph(str(log.action), body_style)
        model = Paragraph(str(log.model_name), body_style)
        record_id = Paragraph(str(log.record_id), body_style)
        ip = Paragraph(str(log.ip_address), body_style)
        changes = Paragraph(str(log.changes), body_style)  # wrapped JSON
        description = Paragraph(str(log.description), body_style)

        data.append([timestamp, user, action, model, record_id, ip, changes])

    # ----- TABLE -----
    table = Table(data, repeatRows=1)  # keep header on each page

    table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor("#2c3e50")),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
        ('FONTNAME', (0, 0), (-1, -1), 'Helvetica'),
        ('FONTSIZE', (0, 0), (-1, -1), 8),
        ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ('GRID', (0, 0), (-1, -1), 0.5, colors.grey),
    ]))

    # This tells ReportLab to allow row splitting instead of errors
    table.splitByRow = True
    table.allowSplitting = True

    # Build PDF
    doc.build([table])

    buffer.seek(0)
    return HttpResponse(buffer, content_type='application/pdf')



# -------------------------
# Delete log
# -------------------------
@login_required
def delete_log(request, pk):
    AuditLog.objects.filter(pk=pk).delete()
    return redirect("audit_logs")


# -------------------------
# Audit Details
# -------------------------
@login_required
def audit_detail(request, pk):
    log = get_object_or_404(AuditLog, pk=pk)
    return render(request, "log_detail_partial.html", {"log": log})

