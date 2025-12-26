from rest_framework.permissions import BasePermission, SAFE_METHODS

class IsOwnerOrManager(BasePermission):

    def has_object_permission(self, request, view, obj):
        user = request.user

        # Admins & Managers can do anything
        if user.is_superuser or user.groups.filter(name__in=["Admin", "Manager"]).exists():
            return True

        # Staff or normal user can only access their own objects
        return obj.created_by == request.user

    def has_permission(self, request, view):
        # Anyone authenticated can use the endpoint
        return request.user and request.user.is_authenticated

