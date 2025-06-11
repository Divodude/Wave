
from rest_framework import generics
from api.models import Music, Album , MusicRoom
from api.serializers import MusicSerializer, AlbumSerializer , MusicRoomSerializer
from django_filters.rest_framework import DjangoFilterBackend
import django_filters
from rest_framework import viewsets
from api import ratelimiter
















class MusicFilter(django_filters.FilterSet):
    title = django_filters.CharFilter(field_name='name', lookup_expr='icontains')

    class Meta:
        model = Music
        fields = ['name']




class MusicListView(generics.ListCreateAPIView):
    queryset = Music.objects.all()
   
    serializer_class = MusicSerializer
    filter_backends = [DjangoFilterBackend]
    filterset_class = MusicFilter



class MusicDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Music.objects.all()
    serializer_class = MusicSerializer


class AlbumListView(generics.ListCreateAPIView):
    queryset = Album.objects.all()
    serializer_class = AlbumSerializer
class AlbumDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Album.objects.all()
    serializer_class = AlbumSerializer






class MusicRoomViewSet(viewsets.ModelViewSet):
    throttle_classes = [ratelimiter.AnonymousSessionTimeThrottle]

    queryset = MusicRoom.objects.all()
    serializer_class = MusicRoomSerializer