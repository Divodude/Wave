# Use official Python image
FROM python:3.11-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential libpq-dev curl \
    && apt-get clean

# Install pipenv/venv dependencies
COPY req.txt .
RUN pip install --no-cache-dir -r req.txt

# Copy project files
COPY . .

# Collect static files (optional if using whitenoise or other)


# Expose port (Render looks for $PORT env, default 8000)
EXPOSE 8000

# Run with Gunicorn and Uvicorn worker
CMD gunicorn music_backend.asgi:application \
    -k uvicorn.workers.UvicornWorker \
    --bind 0.0.0.0:$PORT \
    --log-level debug
