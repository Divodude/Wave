from rest_framework import serializers
from .models import Music, Album, MusicRoom
from django.contrib.auth.models import User
from .models import SubS


class MusicSerializer(serializers.ModelSerializer):
    class Meta:
        model = Music
        fields = '__all__'


class AlbumSerializer(serializers.ModelSerializer):
    songs = MusicSerializer(many=True, read_only=True)  # using related_name='songs'

    class Meta:
        model = Album
        fields = '__all__'


class MusicRoomSerializer(serializers.ModelSerializer):
    class Meta:
        model = MusicRoom
        fields = '__all__'


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True)

    class Meta:
        model = User
        fields = ['username', 'email', 'password']

    def create(self, validated_data):
        user = User.objects.create_user(
            username=validated_data['username'],
            email=validated_data.get('email'),
            password=validated_data['password']
        )
        return user


class SubscriptionSerializer(serializers.ModelSerializer):
    class Meta:
        model = SubS
        fields = ['plan_name', 'is_active', 'started_at']