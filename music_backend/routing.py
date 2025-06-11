from django.urls import re_path
from api import realtime_music

websocket_urlpatterns = [
    re_path(r'ws/music/(?P<room_name>\w+)/$', realtime_music.MusicRoomConsumer.as_asgi()),
]
