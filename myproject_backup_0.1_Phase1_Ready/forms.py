from django import forms
from .models import APIToken
from django.contrib.auth.forms import PasswordChangeForm

class StyledPasswordChangeForm(PasswordChangeForm):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        for field in self.fields.values():
            field.widget.attrs.update({
                'class': 'form-control',
                'style': 'width:100%;'
            })

class APITokenForm(forms.ModelForm):
    class Meta:
        model = APIToken
        fields = ['section', 'IP', 'form_id', 'token']
