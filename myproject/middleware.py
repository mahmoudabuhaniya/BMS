from django.conf import settings
from django.shortcuts import redirect
from django.utils import timezone

import threading

_thread_locals = threading.local()

def get_current_user():
    return getattr(_thread_locals, "user", None)

class CurrentUserMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        _thread_locals.user = request.user if request.user.is_authenticated else None
        return self.get_response(request)


class AutoLogoutMiddleware:
    """
    Middleware to log out users after SESSION_COOKIE_AGE of inactivity
    and redirect to the login page.
    """
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        if not request.user.is_authenticated:
            return self.get_response(request)

        # Get the last activity timestamp from the session
        last_activity = request.session.get('last_activity')
        now = timezone.now().timestamp()

        if last_activity:
            idle_time = now - last_activity
            if idle_time > settings.SESSION_COOKIE_AGE:
                # Clear session and redirect to login page
                from django.contrib.auth import logout
                logout(request)
                return redirect(settings.LOGIN_URL)

        # Update last activity time
        request.session['last_activity'] = now

        response = self.get_response(request)
        return response
