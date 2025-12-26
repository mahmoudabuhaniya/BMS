from django.urls import path
from ..mobile_lookups import lookup_ipnames, lookup_sectors
from ..mobile_sync import full_sync, incremental_sync
from .mobile_actions import create_beneficiary, update_beneficiary, delete_beneficiary, restore_beneficiary

urlpatterns = [
    # Sync
    path("sync/full/", full_sync),
    path("sync/incremental/", incremental_sync),

    # Actions
    path("action/create/", create_beneficiary),
    path("action/update/", update_beneficiary),
    path("action/delete/", delete_beneficiary),
    path("action/restore/", restore_beneficiary),

    # Lookups
    path("lookups/ipnames/", lookup_ipnames),
    path("lookups/sectors/", lookup_sectors),
]
