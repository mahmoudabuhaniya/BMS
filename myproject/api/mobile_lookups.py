# myproject/mobile_api/mobile_lookups.py

from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt

from myproject.api.mobile_serializers import serialize_beneficiary
from myproject.models import Beneficiary, Supply, APIToken   # adjust import if needed
from rest_framework.decorators import (
    api_view,
    authentication_classes,
    permission_classes,
)
from rest_framework.permissions import IsAuthenticated
from rest_framework_simplejwt.authentication import JWTAuthentication
from rest_framework.pagination import PageNumberPagination
from rest_framework import permissions
from rest_framework.response import Response



# Pagination: 100 per page
class BeneficiaryPagination(PageNumberPagination):
    page_size = 100
    max_page_size = 1000
    
# ---------------------------------------------------------
# 📌 IP Name Lookup
# ---------------------------------------------------------
@authentication_classes([JWTAuthentication])
@permission_classes([permissions.IsAuthenticated])
def lookup_ipnames(request):
    
    """
    Returns distinct IP_Name values for dropdown lists.
    Used by Flutter → ApiService.fetchIPNames()
    """
    values = (
        APIToken.objects.values_list("IP", flat=True)
        .exclude(IP__isnull=True)
        .exclude(IP__exact="")
        .distinct()
        .order_by("IP")
    )

    return JsonResponse({
        "ipnames": list(values)
    })


# ---------------------------------------------------------
# 📌 Sector Lookup
# ---------------------------------------------------------
@authentication_classes([JWTAuthentication])
@permission_classes([permissions.IsAuthenticated])
def lookup_sectors(request):
    
    """
    Returns distinct Sector values for dropdown lists.
    Used by Flutter → ApiService.fetchSectors()
    """
    values = (
        APIToken.objects.values_list("section", flat=True)
        .exclude(section__isnull=True)
        .exclude(section__exact="")
        .distinct()
        .order_by("section")
    )

    return JsonResponse({
        "sectors": list(values)
    })


# ---------------------------------------------------------
# 📌 (Optional) Additional Lookups
# ---------------------------------------------------------
@authentication_classes([JWTAuthentication])
@permission_classes([permissions.IsAuthenticated])
def lookup_governorates(request):
    values = (
        Beneficiary.all_objects.values_list("Governorate", flat=True)
        .exclude(Governorate__isnull=True)
        .exclude(Governorate__exact="")
        .distinct()
        .order_by("Governorate")
    )
    return JsonResponse({"governorates": list(values)})


@authentication_classes([JWTAuthentication])
@permission_classes([permissions.IsAuthenticated])
def lookup_genders(request):
    values = (
        Beneficiary.all_objects.values_list("Gender", flat=True)
        .exclude(Gender__isnull=True)
        .exclude(Gender__exact="")
        .distinct()
        .order_by("Gender")
    )
    return JsonResponse({"genders": list(values)})
