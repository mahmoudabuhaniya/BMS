import os
import sys

# Path to your Django project (inside subfolder "inform")
PROJECT_DIR = os.path.join(os.path.dirname(__file__), "inform")
sys.path.insert(0, PROJECT_DIR)

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "myproject.settings")

from django.core.wsgi import get_wsgi_application
application = get_wsgi_application()
