# myproject/mobile_api/mobile_sync.py

from django.core.paginator import Paginator
from django.http import JsonResponse
from django.utils.dateparse import parse_datetime
from django.utils import timezone

from requests import request
from rest_framework.decorators import (
    api_view,
    authentication_classes,
    permission_classes,
)
from rest_framework_simplejwt.authentication import JWTAuthentication
from rest_framework import permissions

from myproject.models import Beneficiary
from myproject.api.mobile_serializers import serialize_beneficiary, serialize_beneficiary_list
from django.utils.dateparse import parse_datetime
from django.utils import timezone
from rest_framework.response import Response
from rest_framework import status




# ---------------------------------------------------------
# 🔧 FULL SYNC — used only for first installation
# ---------------------------------------------------------
@api_view(["POST"])
@authentication_classes([JWTAuthentication])
@permission_classes([permissions.IsAuthenticated])
def full_sync(request):
    page = int(request.data.get("page", 1))
    page_size = int(request.data.get("page_size", 1000))

    qs = Beneficiary.all_objects.all().order_by("id")

    paginator = Paginator(qs, page_size)
    current_page = paginator.get_page(page)

    data = [serialize_beneficiary(b) for b in current_page.object_list]

    return JsonResponse({
        "count": paginator.count,
        "page": page,
        "page_size": page_size,
        "has_next": current_page.has_next(),  # 🔥 IMPORTANT
        "results": data,
        "server_time": timezone.now().isoformat(),
    })



# ---------------------------------------------------------
# 🔄 INCREMENTAL SYNC — Flutter sends updated_after timestamp
# ---------------------------------------------------------
@api_view(["POST"])
@authentication_classes([JWTAuthentication])
@permission_classes([permissions.IsAuthenticated])
def incremental_sync(request):

    print("RAW updated_after:", request.GET.get("updated_after"))
    print("ALL QUERY PARAMS:", request.GET.dict())

    updated_after = request.data.get("updated_after")
    page = int(request.data.get("page", 1))
    page_size = int(request.data.get("page_size", 500))

    if not updated_after:
        return Response(
            {"error": "updated_after is required"},
            status=status.HTTP_400_BAD_REQUEST
        )

    dt = parse_datetime(updated_after)
    if not dt:
        return Response(
            {"error": "Invalid datetime format"},
            status=status.HTTP_400_BAD_REQUEST
        )

    qs = Beneficiary.all_objects.filter(updated_at__gt=dt).order_by("id")

    paginator = Paginator(qs, page_size)
    page_obj = paginator.get_page(page)

    data = serialize_beneficiary_list(page_obj.object_list)

    return Response({
        "count": paginator.count,
        "page": page,
        "page_size": page_size,
        "has_next": page_obj.has_next(),
        "results": data,
        "server_time": timezone.now().isoformat()
    })


