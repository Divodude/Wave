import os
from channels.routing import ProtocolTypeRouter, URLRouter
from channels.auth import AuthMiddlewareStack
from django.core.asgi import get_asgi_application
import music_backend.routing  # Update to your project name

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "music_backend.settings")

application = ProtocolTypeRouter({
    "http": get_asgi_application(),
    "websocket": AuthMiddlewareStack(
        URLRouter(
            music_backend.routing.websocket_urlpatterns
        )
    ),
})
