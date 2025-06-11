# websocket_throttles.py
import time
from datetime import date, datetime, timedelta
from django.core.cache import cache

class WebSocketRateLimiter:

    
    MAX_CONNECTIONS_PER_SESSION = 3  # Max concurrent connections per session
    MAX_CONNECTIONS_PER_IP = 5       # Max concurrent connections per IP
    
    # Message rate limits
    MESSAGES_PER_MINUTE = 30         # Max messages per minute per connection
    BURST_LIMIT = 10                 # Max burst messages in short time
    BURST_WINDOW = 10                # Burst window in seconds
    
    # Time-based limits for anonymous users
    DAILY_TIME_LIMIT_SECONDS = 5  # 1 hour per day for anonymous users
    
    @staticmethod
    def check_connection_limit(session_key=None, ip_address=None):
        """
        Check if connection is allowed based on concurrent connection limits
        """
        if session_key:
            session_connections = cache.get(f"ws_connections_session_{session_key}", 0)
            if session_connections >= WebSocketRateLimiter.MAX_CONNECTIONS_PER_SESSION:
                return False, "Too many concurrent connections for this session"
        
        if ip_address:
            ip_connections = cache.get(f"ws_connections_ip_{ip_address}", 0)
            if ip_connections >= WebSocketRateLimiter.MAX_CONNECTIONS_PER_IP:
                return False, "Too many concurrent connections from this IP"
        
        return True, "Connection allowed"
    
    @staticmethod
    def register_connection(session_key=None, ip_address=None):
        """
        Register a new WebSocket connection
        """
        if session_key:
            key = f"ws_connections_session_{session_key}"
            current = cache.get(key, 0)
            cache.set(key, current + 1, timeout=3600)
        
        if ip_address:
            key = f"ws_connections_ip_{ip_address}"
            current = cache.get(key, 0)
            cache.set(key, current + 1, timeout=3600)
    
    @staticmethod
    def unregister_connection(session_key=None, ip_address=None):
        """
        Unregister a WebSocket connection
        """
        if session_key:
            key = f"ws_connections_session_{session_key}"
            current = cache.get(key, 0)
            if current > 0:
                cache.set(key, current - 1, timeout=3600)
        
        if ip_address:
            key = f"ws_connections_ip_{ip_address}"
            current = cache.get(key, 0)
            if current > 0:
                cache.set(key, current - 1, timeout=3600)
    
    @staticmethod
    def check_message_rate_limit(connection_id):
        """
        Check if message is allowed based on rate limiting
        """
        now = time.time()
        
        # Check burst limit
        burst_key = f"ws_burst_{connection_id}"
        burst_data = cache.get(burst_key, {'count': 0, 'window_start': now})
        
        # Reset burst window if needed
        if now - burst_data['window_start'] > WebSocketRateLimiter.BURST_WINDOW:
            burst_data = {'count': 0, 'window_start': now}
        
        if burst_data['count'] >= WebSocketRateLimiter.BURST_LIMIT:
            return False, "Burst limit exceeded"
        
        # Check per-minute limit
        minute_key = f"ws_minute_{connection_id}"
        minute_data = cache.get(minute_key, {'count': 0, 'window_start': now})
        
        # Reset minute window if needed
        if now - minute_data['window_start'] > 60:
            minute_data = {'count': 0, 'window_start': now}
        
        if minute_data['count'] >= WebSocketRateLimiter.MESSAGES_PER_MINUTE:
            return False, "Rate limit exceeded"
        
        # Update counters
        burst_data['count'] += 1
        minute_data['count'] += 1
        
        cache.set(burst_key, burst_data, timeout=WebSocketRateLimiter.BURST_WINDOW + 10)
        cache.set(minute_key, minute_data, timeout=70)
        
        return True, "Message allowed"
    
    @staticmethod
    def check_anonymous_time_limit(session_key, user_is_authenticated=False):
        """
        Check if anonymous user has exceeded daily time limit
        """
        if user_is_authenticated:
            return True, "Authenticated user - no time limit"
        
        try:
            # Import here to avoid Django setup issues
            from api.models import AnonymousSessionUsage
            
            usage = AnonymousSessionUsage.objects.filter(
                session_key=session_key,
                date=date.today()
            ).first()
            
            if usage and usage.seconds_used >= WebSocketRateLimiter.DAILY_TIME_LIMIT_SECONDS:
                return False, "Daily time limit exceeded"
            
            return True, "Time limit OK"
        except Exception as e:
            # If there's an error checking the database, allow the connection
            # but log the error
            print(f"Error checking time limit: {e}")
            return True, "Error checking time limit - allowing connection"
    
    @staticmethod
    def track_connection_time(session_key, user_is_authenticated=False):
        """
        Start tracking connection time for anonymous users
        """
        if user_is_authenticated:
            return None
        
        connection_start_key = f"ws_start_{session_key}"
        cache.set(connection_start_key, time.time(), timeout=3600)
        return connection_start_key
    
    @staticmethod
    def update_usage_time(session_key, user_is_authenticated=False):
        """
        Update the usage time in database when connection ends
        """
        if user_is_authenticated:
            return
        
        connection_start_key = f"ws_start_{session_key}"
        start_time = cache.get(connection_start_key)
        
        if start_time:
            duration = int(time.time() - start_time)
            
            try:
                # Import here to avoid Django setup issues
                from api.models import AnonymousSessionUsage
                
                usage, created = AnonymousSessionUsage.objects.get_or_create(
                    session_key=session_key,
                    date=date.today(),
                    defaults={'seconds_used': 0}
                )
                usage.seconds_used += duration
                usage.save()
                
                # Clean up cache
                cache.delete(connection_start_key)
            except Exception as e:
                print(f"Error updating usage time: {e}")


class WebSocketConnectionManager:
    """
    Enhanced connection manager with rate limiting
    """
    
    def __init__(self, consumer_instance):
        self.consumer = consumer_instance
        self.connection_id = f"{consumer_instance.channel_name}_{int(time.time())}"
        self.session_key = None
        self.ip_address = None
        self.user_is_authenticated = False
        self.time_tracker_key = None
    
    def get_client_info(self):
        """Extract client information from WebSocket scope"""
        # Get session key
        session = self.consumer.scope.get('session')
        if session:
            if not session.session_key:
                session.save()
            self.session_key = session.session_key
        
        # Get IP address
        headers = dict(self.consumer.scope.get('headers', []))
        x_forwarded_for = headers.get(b'x-forwarded-for')
        if x_forwarded_for:
            self.ip_address = x_forwarded_for.decode().split(',')[0].strip()
        else:
            self.ip_address = self.consumer.scope.get('client', ['unknown'])[0]
        
        # Check if user is authenticated
        user = self.consumer.scope.get('user')
        self.user_is_authenticated = user and user.is_authenticated
    
    async def check_connection_allowed(self):
        """
        Check if connection should be allowed
        """
        self.get_client_info()
        
        # Check concurrent connection limits
        allowed, message = WebSocketRateLimiter.check_connection_limit(
            self.session_key, self.ip_address
        )
        if not allowed:
            return False, message
        
        # Check anonymous user time limits
        if self.session_key:
            allowed, message = WebSocketRateLimiter.check_anonymous_time_limit(
                self.session_key, self.user_is_authenticated
            )
            if not allowed:
                return False, message
        
        return True, "Connection allowed"
    
    def register_connection(self):
        """Register the connection and start time tracking"""
        WebSocketRateLimiter.register_connection(self.session_key, self.ip_address)
        
        if self.session_key:
            self.time_tracker_key = WebSocketRateLimiter.track_connection_time(
                self.session_key, self.user_is_authenticated
            )
    
    def unregister_connection(self):
        """Unregister the connection and update usage time"""
        WebSocketRateLimiter.unregister_connection(self.session_key, self.ip_address)
        
        if self.session_key:
            WebSocketRateLimiter.update_usage_time(
                self.session_key, self.user_is_authenticated
            )
    
    def check_message_allowed(self):
        """Check if message should be allowed"""
        return WebSocketRateLimiter.check_message_rate_limit(self.connection_id)


# Usage example for your MusicRoomConsumer:
"""
# Modified connect method in MusicRoomConsumer:

async def connect(self):
    # Initialize rate limiter
    self.rate_limiter = WebSocketConnectionManager(self)
    
    # Check if connection is allowed
    allowed, message = await self.rate_limiter.check_connection_allowed()
    if not allowed:
        await self.close(code=4008, reason=message.encode())
        return
    
    # Register the connection
    self.rate_limiter.register_connection()
    
    # ... rest of your existing connect logic ...
    
    await self.accept()

# Modified disconnect method:
async def disconnect(self, close_code):
    # Unregister connection for rate limiting
    if hasattr(self, 'rate_limiter'):
        self.rate_limiter.unregister_connection()
    
    # ... rest of your existing disconnect logic ...

# Modified receive method:
async def receive(self, text_data):
    # Check message rate limit
    if hasattr(self, 'rate_limiter'):
        allowed, message = self.rate_limiter.check_message_allowed()
        if not allowed:
            await self.send_error(f"Rate limit exceeded: {message}")
            return
    
    # ... rest of your existing receive logic ...
"""