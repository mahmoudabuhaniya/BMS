from rest_framework import serializers
from .models import Beneficiary

class BeneficiarySerializer(serializers.ModelSerializer):

    class Meta:
        model = Beneficiary
        fields = '__all__'

    # Allow partial updates
    def update(self, instance, validated_data):
        return super().update(instance, validated_data)
