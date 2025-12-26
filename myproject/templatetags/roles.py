from django import template

register = template.Library()

@register.filter
def in_group(user, group_names):
    """
    Usage:
        {% if user|in_group:"Admin,Manager" %}
    """
    if not user.is_authenticated:
        return False

    groups = [g.strip() for g in group_names.split(",")]
    return user.groups.filter(name__in=groups).exists()
