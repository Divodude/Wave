
from rest_framework import generics
from api.models import Music, Album , MusicRoom
from api.serializers import MusicSerializer, AlbumSerializer , MusicRoomSerializer
from django_filters.rest_framework import DjangoFilterBackend
import django_filters
from rest_framework import viewsets
from django.contrib.auth.models import User
from rest_framework.permissions import IsAuthenticated















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
    permission_classes = [IsAuthenticated] 



class MusicDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Music.objects.all()
    serializer_class = MusicSerializer
    permission_classes = [IsAuthenticated] 


class AlbumListView(generics.ListCreateAPIView):
    queryset = Album.objects.all()
    serializer_class = AlbumSerializer
    permission_classes = [IsAuthenticated] 
class AlbumDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Album.objects.all()
    serializer_class = AlbumSerializer
    permission_classes = [IsAuthenticated] 






class MusicRoomViewSet(viewsets.ModelViewSet):
   

    queryset = MusicRoom.objects.all()
    serializer_class = MusicRoomSerializer
    permission_classes = [IsAuthenticated] 






from rest_framework import generics, permissions, status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.authtoken.models import Token

from django.contrib.auth import authenticate
from django.contrib.auth.models import User
from .models import SubS
from .serializers import RegisterSerializer, SubscriptionSerializer
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework import permissions




# ✅ REGISTER
class RegisterView(generics.CreateAPIView):
    queryset = User.objects.all()
    serializer_class = RegisterSerializer
    permission_classes = [permissions.AllowAny]

    def create(self, request, *args, **kwargs):
        response = super().create(request, *args, **kwargs)
        user = User.objects.get(username=response.data['username'])
        token, _ = Token.objects.get_or_create(user=user)
        return Response({'token': token.key})


# ✅ LOGIN
class LoginView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        username = request.data.get('username')
        password = request.data.get('password')
        user = authenticate(username=username, password=password)

        if user:
            token, _ = Token.objects.get_or_create(user=user)
            return Response({'token': token.key})
        return Response({'error': 'Invalid credentials'})


# ✅ MOCK SUBSCRIPTION
class MockSubscribeView(APIView):
    permission_classes = [AllowAny]
    

    def post(self, request):
        user = request.user
        SubS.objects.update_or_create(
            user=user,
            defaults={'is_active': True, 'plan_name': 'Premium'},
        )
        return Response({'message': 'Subscription activated!'})


# ✅ CHECK SUBSCRIPTION STATUS
class SubscriptionStatusView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        sub = SubS.objects.filter(user=request.user).first()
        if sub and sub.is_active:
            return Response({'subscribed': True, 'plan': sub.plan_name})
        return Response({'subscribed': False})