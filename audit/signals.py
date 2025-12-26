
from django.db.models.signals import pre_save, post_save, pre_delete
from django.dispatch import receiver
from django.forms.models import model_to_dict
from django.contrib.auth.models import AnonymousUser
from audit.models import AuditLog
from myproject.models import Beneficiary, Supply
from datetime import date, datetime
from django.db.models import Model
from myproject.middleware import get_current_user



def _set_audit_fields(instance):
    user = get_current_user()
    username = user.username if user else None

    if instance.pk:
        instance.updated_by = username
    else:
        instance.created_by = username


@receiver(pre_save, sender=Beneficiary)
def beneficiary_audit(sender, instance, **kwargs):
    _set_audit_fields(instance)


@receiver(pre_save, sender=Supply)
def supply_audit(sender, instance, **kwargs):
    _set_audit_fields(instance)


def make_json_safe(value):
    if isinstance(value, (date, datetime)):
        return value.isoformat()
    if isinstance(value, Model):
        return str(value)
    if isinstance(value, dict):
        return {k: make_json_safe(v) for k, v in value.items()}
    if isinstance(value, list):
        return [make_json_safe(v) for v in value]
    return value

def get_ip(request):
    if request is None:
        return None
    x_forwarded_for = request.META.get("HTTP_X_FORWARDED_FOR")
    if x_forwarded_for:
        return x_forwarded_for.split(",")[0]
    return request.META.get("REMOTE_ADDR")

def get_request():
    try:
        from audit.threadlocal import thread_local
        return getattr(thread_local, "request", None)
    except:
        return None

def make_json_safe(data):
    if isinstance(data, dict):
        return {k: make_json_safe(v) for k, v in data.items()}
    elif isinstance(data, list):
        return [make_json_safe(v) for v in data]
    elif isinstance(data, datetime):
        return data.isoformat()
    else:
        return data

# ---------- PRE-SAVE ----------
@receiver(pre_save)
def audit_pre_save(sender, instance, **kwargs):
    if sender.__name__ == "AuditLog":
        return
    if not instance.pk:
        instance._old_data = None
    else:
        try:
            old_obj = sender.objects.get(pk=instance.pk)
            instance._old_data = model_to_dict(old_obj)
        except sender.DoesNotExist:
            instance._old_data = None

# ---------- POST-SAVE ----------
@receiver(post_save)
def audit_post_save(sender, instance, created, **kwargs):
    if sender.__name__ == "AuditLog":
        return

    request = get_request()
    user = request.user if request and request.user.is_authenticated else None
    ip = get_ip(request)

    changes = {}

    if created:
        changes["info"] = f"Created {sender.__name__} record with ID {instance.pk}"
        action = "CREATE"
    else:
        # Collect only simple field changes (exclude permissions, m2m, relations)
        simple_fields = [f.name for f in sender._meta.fields]
        changes = {f: str(getattr(instance, f)) for f in simple_fields}
        action = "UPDATE"
    

    AuditLog.objects.create(
        user=user,
        action="CREATE" if created else "UPDATE",
        model_name=sender.__name__,
        record_id=str(instance.pk),
        changes=changes,
        description="New Data Instance Created" if created else "Data Instance Updated",
        ip_address=ip
    )

# ---------- DELETE ----------
@receiver(pre_delete)
def audit_delete(sender, instance, using, **kwargs):
    if sender.__name__ == 'AuditLog':
        return

    request = get_request()
    user = request.user if request and request.user.is_authenticated else None
    ip = get_ip(request)

    # Serialize instance safely
    raw_data = {
        field.name: getattr(instance, field.name)
        for field in instance._meta.fields
    }

    from audit.models import AuditLog
    from datetime import date, datetime
    from django.db.models import Model

    def make_json_safe(val):
        if isinstance(val, (date, datetime)):
            return val.isoformat()
        if isinstance(val, Model):
            return str(val)
        return val

    safe_data = {k: make_json_safe(v) for k, v in raw_data.items()}

    AuditLog.objects.create(
        user=user,
        action='DELETE',
        model_name=sender.__name__,
        changes=safe_data,     # ✅ FIELD THAT EXISTS
        ip_address=ip
    )


