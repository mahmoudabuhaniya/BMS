from django.contrib import admin
from .models import Workspace, Channel, Flow, Contact, FlowRun, APIToken

@admin.register(Workspace)
class WorkspaceAdmin(admin.ModelAdmin):
    list_display = ('name', 'uuid', 'timezone', 'country', 'last_synced')
    search_fields = ('name', 'uuid')
    readonly_fields = ('last_synced',)

@admin.register(Channel)
class ChannelAdmin(admin.ModelAdmin):
    list_display = ('name', 'address', 'uuid', 'last_synced')
    list_filter = ('created_on',)
    search_fields = ('name', 'uuid', 'address')
    readonly_fields = ('last_synced',)

@admin.register(Flow)
class FlowAdmin(admin.ModelAdmin):
    list_display = ('name', 'uuid', 'runs', 'last_synced')
    list_filter = ('runs',)
    search_fields = ('name', 'uuid')
    readonly_fields = ('last_synced',)

@admin.register(Contact)
class ContactAdmin(admin.ModelAdmin):
    list_display = ('name', 'uuid', 'status', 'language', 'last_synced')
    list_filter = ('language',)
    search_fields = ('name', 'uuid')
    readonly_fields = ('last_synced',)

@admin.register(FlowRun)
class FlowRunAdmin(admin.ModelAdmin):
    list_display = ('uid','uuid','flowuuid', 'contact', 'exit_type', 'created_on', 'urn', 'exited_on', 'last_synced')
    list_filter = ('exit_type', 'flowuuid', 'created_on')
    search_fields = ('uuid', 'flow__name', 'contact__name')
    readonly_fields = ('last_synced',)
    
@admin.register(APIToken)
class APIToken(admin.ModelAdmin):
    list_display = ('id','name','token', 'last_used', 'created_at')
    list_filter = ('name', 'token')
    search_fields = ('token',)
    readonly_fields = ('id',)