from rest_framework import serializers
from .models import Music, Album, MusicRoom


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