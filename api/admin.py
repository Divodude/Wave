from django.contrib import admin
from .models import Album, Music, MusicRoom, AnonymousSessionUsage, SubS

@admin.register(Album)
class AlbumAdmin(admin.ModelAdmin):
    list_display = ('name', 'artist')
    search_fields = ('name', 'artist')

@admin.register(Music)
class MusicAdmin(admin.ModelAdmin):
    list_display = ('name', 'artist', 'duration', 'song_album')
    search_fields = ('name', 'artist')
    list_filter = ('song_album',)

@admin.register(MusicRoom)
class MusicRoomAdmin(admin.ModelAdmin):
    list_display = ('name', 'created_at')
    search_fields = ('name',)

@admin.register(AnonymousSessionUsage)
class AnonymousSessionUsageAdmin(admin.ModelAdmin):
    list_display = ('session_key', 'date', 'seconds_used')
    search_fields = ('session_key',)

@admin.register(SubS)
class SubSAdmin(admin.ModelAdmin):
    list_display = ('user', 'plan_name', 'is_active', 'started_at')
    search_fields = ('user__username', 'plan_name')
    list_filter = ('is_active', 'plan_name')
