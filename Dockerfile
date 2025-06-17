FROM python:3.9-slim

# Prevent .pyc files and force stdout/stderr logs
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libpq-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy dependency file and install Python dependencies
COPY req.txt .
RUN pip install --upgrade pip && pip install --no-cache-dir -r req.txt

# Copy project files
COPY . .

# Copy environment file
COPY .env .

# Explicitly set Django settings module (if not set via .env)
ENV DJANGO_SETTINGS_MODULE=music_backend.settings

# Optional: collect static only if you actually serve static files
# RUN python manage.py collectstatic --noinput

# Expose port 8080 for Google Cloud Run
EXPOSE 8080

# Launch with ASGI using Uvicorn
CMD ["uvicorn", "music_backend.asgi:application", "--host", "0.0.0.0", "--port", "8080"]
