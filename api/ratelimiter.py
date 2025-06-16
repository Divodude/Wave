# throttles.py
from rest_framework.throttling import BaseThrottle
from datetime import date
from api.models import AnonymousSessionUsage

class AnonymousSessionTimeThrottle(BaseThrottle):
    DAILY_LIMIT = 2 * 60 * 60  

    def allow_request(self, request, view):
        if request.user.is_authenticated:
            return True 

        session_key = request.session.session_key
        if not session_key:
            request.session.save()
            session_key = request.session.session_key

        usage = AnonymousSessionUsage.objects.filter(
            session_key=session_key,
            date=date.today()
        ).first()

        if usage and usage.seconds_used >= self.DAILY_LIMIT:
            return False
        return True
