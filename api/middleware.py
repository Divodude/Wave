from django.utils.timezone import now
from api.models import AnonymousSessionUsage




class SessionUsageMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        start_time = now()
        response = self.get_response(request)
        end_time = now()

        if not request.user.is_authenticated and request.session.session_key:
            duration = int((end_time - start_time).total_seconds())
            today = end_time.date()
            session_key = request.session.session_key
            usage, _ = AnonymousSessionUsage.objects.get_or_create(
                session_key=session_key, date=today
            )
            usage.seconds_used += duration
            usage.save()
        return response