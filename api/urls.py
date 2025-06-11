from django.urls import include 
from django.contrib import admin
from django.urls import path

from api.views import MusicListView, MusicDetailView, AlbumListView, AlbumDetailView,MusicRoomViewSet
from django.conf import settings
from django.conf.urls.static import static
from rest_framework.routers import DefaultRouter
router=DefaultRouter()
urlpatterns = [
    
    path('music/',view=MusicListView.as_view(), name='music-list'),
    path('music/<int:pk>/', view=MusicDetailView.as_view(), name='music-detail'),
    path('album/', view=AlbumListView.as_view(), name='album-list'),
    path('album/<int:pk>/', view=AlbumDetailView.as_view(), name='album-detail'),
   

]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)