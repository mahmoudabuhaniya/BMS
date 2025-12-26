from django import forms
from .models import APIToken

class APITokenForm(forms.ModelForm):
    class Meta:
        model = APIToken
        fields = ['name', 'token']
