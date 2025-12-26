# myproject/mobile_api/urls_mobile.py

from django.urls import path
from .mobile_orchestration import orchestrate_mobile
from .mobile_sync import full_sync, incremental_sync
from .mobile_lookups import lookup_ipnames, lookup_sectors

urlpatterns = [
    
    # ---------------------------------------
    # 🔥 SINGLE ENTRY FOR CREATE/UPDATE/DELETE/RESTORE
    # ---------------------------------------
    path("orchestrate/", orchestrate_mobile, name="mobile_orchestrate"),

    # ---------------------------------------
    # 🔄 SYNC ENDPOINTS
    # ---------------------------------------
    path("sync/full/", full_sync, name="mobile_full_sync"),
    path("sync/incremental/", incremental_sync, name="mobile_incremental_sync"),

    # ---------------------------------------
    # 📌 LOOKUP ENDPOINTS (IP Names, Sectors)
    # ---------------------------------------
    path("lookups/ipnames/", lookup_ipnames, name="mobile_ipnames"),
    path("lookups/sectors/", lookup_sectors, name="mobile_sectors"),
]
