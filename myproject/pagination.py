from rest_framework.pagination import PageNumberPagination

class CustomPageNumberPagination(PageNumberPagination):
    page_size = 500  # Default page size
    page_size_query_param = 'page_size'  # Allow dynamic size
    max_page_size = 1000  # Prevent huge payloads