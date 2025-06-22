"""
Django settings for music project.
"""

from pathlib import Path
import os
from dotenv import load_dotenv, find_dotenv
import urllib.parse

# Build paths inside the project like this: BASE_DIR / 'subdir'.
BASE_DIR = Path(__file__).resolve().parent.parent

# Load environment variables
load_dotenv(find_dotenv())

# Security settings
SECRET_KEY=os.environ.get('DJANGO_SECRET_KEY')
DEBUG =False
ALLOWED_HOSTS = ["*"] if DEBUG else ["api-1039005314066.europe-west1.run.app"]

# Application definition
INSTALLED_APPS = [
    'django.contrib.admin',
    'storages',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'django_filters',
    'rest_framework',
    'rest_framework.authtoken',
    'channels',
    'api',
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'corsheaders.middleware.CorsMiddleware',
    'whitenoise.middleware.WhiteNoiseMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
    'api.middleware.SessionUsageMiddleware',
]



CSRF_TRUSTED_ORIGINS = [
    "https://api-1039005314066.europe-west1.run.app",
    "https://yourdomain.com",  # Replace with your frontend domain
    "https://www.yourdomain.com",  # Replace with your frontend domain
]

ROOT_URLCONF = 'music_backend.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'music_backend.wsgi.application'
ASGI_APPLICATION = 'music_backend.asgi.application'

# Database
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.environ.get("DB_NAME"),
        'USER': os.environ.get("DB_USER"),
        'PASSWORD': os.environ.get("DB_PASSWORD"),
        'HOST': os.environ.get("DB_HOST"),
        'PORT': os.environ.get("DB_PORT", "5432"),
        'OPTIONS': {
            'sslmode': 'require',  
        },
    }
}

# Password validation
AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator'},
    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator'},
    {'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator'},
    {'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator'},
]

# Internationalization
LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'UTC'
USE_I18N = True
USE_TZ = True

# Static files
STATIC_URL = '/static/'
STATIC_ROOT = os.path.join(BASE_DIR, 'staticfiles')



# REST Framework
REST_FRAMEWORK = {
    'DEFAULT_FILTER_BACKENDS': ['django_filters.rest_framework.DjangoFilterBackend'],
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework.authentication.TokenAuthentication',
        'rest_framework.authentication.SessionAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.IsAuthenticated',
    ],
    'DEFAULT_THROTTLE_RATES': {
        'anon': '100/hour',
        'user': '1000/hour'
    }
    ,
    'DEFAULT_PAGINATION_CLASS': 'rest_framework.pagination.PageNumberPagination',
    'PAGE_SIZE': 10
}

# CORS Settings
CORS_ALLOW_ALL_ORIGINS = True

# Redis/Channels Configuration
redis_url = os.environ.get("REDIS_URL")
parsed = urllib.parse.urlparse(redis_url)

REDIS_URL = os.environ.get("REDIS_URL")

# Validate Redis URL
if REDIS_URL:
    try:
        # Ensure scheme is present
        if not REDIS_URL.startswith(('redis://', 'rediss://', 'unix://')):
            REDIS_URL = f"redis://{REDIS_URL}"

        parsed = urllib.parse.urlparse(REDIS_URL)  # Optional: check structure

        CHANNEL_LAYERS = {
            'default': {
                'BACKEND': 'channels_redis.core.RedisChannelLayer',
                'CONFIG': {
                    "hosts": [REDIS_URL],
                    "prefix": "sync_song",
                    "expiry": 10,
                    "group_expiry": 120,
                    "capacity": 1000,
                    "channel_capacity": {
                        "http.request": 200,
                        "http.response!*": 100,
                        "websocket.send": 500,
                    },
                },
            },
        }
    except Exception as e:
        print(f"[Redis Config Error] {e}")
        REDIS_URL = None
else:
    print("[Warning] REDIS_URL environment variable not set.")


# SSL Settings (for production)
if not DEBUG:
    SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')
    SECURE_SSL_REDIRECT = True
    SESSION_COOKIE_SECURE = True
    CSRF_COOKIE_SECURE = True


# In settings.py
FIREBASE_ENABLED = False

firebase_credentials_json = os.environ.get("FIREBASE_CREDENTIALS_JSON")
if firebase_credentials_json:
    try:
        import firebase_admin
        from firebase_admin import credentials, storage as fb_storage
        import json

        cred_dict = json.loads(firebase_credentials_json)
        cred = credentials.Certificate(cred_dict)
        firebase_admin.initialize_app(cred, {
            'storageBucket': 'face-recognition-3ba91.appspot.com'
        })
        DEFAULT_FILE_STORAGE = 'api.firebase.FirebaseStorage'
        FIREBASE_ENABLED = True
    except json.JSONDecodeError:
        print("[Warning] FIREBASE_CREDENTIALS_JSON is not valid JSON")
else:
    print("[Info] Firebase not initialized. FIREBASE_CREDENTIALS_JSON not set.")
