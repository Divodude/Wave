# Music Backend API

A Django-based music streaming backend with real-time synchronization capabilities, user authentication, and Firebase storage integration.

## Features

- **Music Management**: Upload, organize, and stream music files
- **Album Organization**: Group songs into albums with cover art
- **Real-time Music Rooms**: Synchronized music playback across multiple users
- **User Authentication**: Token-based authentication with registration/login
- **Subscription System**: Mock subscription management for premium features
- **Firebase Storage**: Cloud storage for music files and cover images
- **Rate Limiting**: Anonymous session time limits for non-premium users
- **WebSocket Integration**: Real-time synchronization using Django Channels

## Tech Stack

- **Backend**: Django 5.x with Django REST Framework
- **Database**: PostgreSQL
- **Cache/Message Broker**: Redis
- **Storage**: Firebase Storage
- **WebSockets**: Django Channels with Redis backend
- **Deployment**: Docker, Google Cloud Run ready

## Installation

### Prerequisites

- Python 3.9+
- PostgreSQL
- Redis
- Firebase project with Storage enabled

### Local Development Setup

1. **Clone the repository**
   ```bash
   git clone <your-repo-url>
   cd music_backend
   ```

2. **Create virtual environment**
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. **Install dependencies**
   ```bash
   pip install -r req.txt
   ```

4. **Environment Variables**
   
   Create a `.env` file in the project root:
   ```env
   # Django Settings
   DJANGO_SECRET_KEY=your-secret-key-here
   
   # Database Configuration
   DB_NAME=your_db_name
   DB_USER=your_db_user
   DB_PASSWORD=your_db_password
   DB_HOST=localhost
   DB_PORT=5432
   
   # Redis Configuration
   REDIS_URL=redis://localhost:6379
   
   # Firebase Configuration
   FIREBASE_CREDENTIALS_JSON={"type": "service_account", "project_id": "your-project-id", ...}
   ```

5. **Database Setup**
   ```bash
   python manage.py makemigrations
   python manage.py migrate
   python manage.py createsuperuser
   ```

6. **Run the development server**
   ```bash
   python manage.py runserver
   ```

### Docker Deployment

1. **Build the Docker image**
   ```bash
   docker build -t music-backend .
   ```

2. **Run with Docker Compose** (create docker-compose.yml)
   ```yaml
   version: '3.8'
   services:
     web:
       build: .
       ports:
         - "8080:8080"
       environment:
         - DJANGO_SECRET_KEY=your-secret-key
         - DB_HOST=db
         - REDIS_URL=redis://redis:6379
       depends_on:
         - db
         - redis
     
     db:
       image: postgres:13
       environment:
         POSTGRES_DB: music_db
         POSTGRES_USER: postgres
         POSTGRES_PASSWORD: password
     
     redis:
       image: redis:alpine
   ```

## API Endpoints

### Authentication
- `POST /register/` - User registration
- `POST /login/` - User login (returns token)

### Music Management
- `GET /music/` - List all music (authenticated users only)
- `GET /music/<id>/` - Get specific music details
- `POST /music/` - Upload new music
- `GET /music/?title=<search>` - Search music by title

### Albums
- `GET /album/` - List all albums (public)
- `GET /album/<id>/` - Get album with songs
- `POST /album/` - Create new album

### Music Rooms
- `GET /api/rooms/` - List music rooms
- `POST /api/rooms/` - Create new music room

### Subscription
- `POST /subscribe/` - Mock subscription activation
- `GET /subscription-status/` - Check subscription status

## WebSocket Integration

### Music Room WebSocket

Connect to: `ws://localhost:8000/ws/music/<room_name>/?user_id=<user_id>`

#### Message Types

**Client to Server:**
```javascript
// Play music
{
  "type": "play",
  "position": 0,
  "song_url": "https://...",
  "song_name": "Song Title",
  "artist_name": "Artist Name",
  "cover_image": "https://..."
}

// Pause music
{
  "type": "pause",
  "position": 120.5
}

// Seek to position
{
  "type": "seek",
  "position": 60.0
}

// Change song
{
  "type": "song_change",
  "song_data": {
    "url": "https://...",
    "name": "New Song",
    "artist": "Artist",
    "cover": "https://..."
  },
  "auto_play": true
}
```

**Server to Client:**
```javascript
// Music control events
{
  "type": "music_control",
  "action": "play|pause|seek|song_change",
  "server_timestamp": 1234567890,
  "position": 120.5,
  "song_data": {...}
}

// Time synchronization
{
  "type": "time_sync",
  "server_timestamp": 1234567890,
  "current_position": 125.3,
  "is_playing": true
}

// User events
{
  "type": "user_joined|user_left",
  "user_id": "user123",
  "participants": ["user1", "user2"]
}
```

## Models

### Music
- `name`: Song title
- `artist`: Artist name
- `song`: Audio file (Firebase Storage)
- `song_cover`: Cover image (Firebase Storage)
- `duration`: Song duration
- `song_album`: Foreign key to Album

### Album
- `name`: Album name
- `artist`: Album artist
- `cover_image`: Album cover (Firebase Storage)
- `songs`: Related songs

### MusicRoom
- `name`: Room name (unique)
- `created_at`: Creation timestamp

### SubS (Subscription)
- `user`: One-to-one with User
- `is_active`: Subscription status
- `plan_name`: Subscription plan
- `started_at`: Subscription start date

## Rate Limiting

Anonymous users are limited to 2 hours of streaming per day. The system tracks usage via session keys and automatically enforces limits.

## Firebase Storage Integration

The project uses custom Firebase storage backend for handling file uploads:

- Music files are stored in `music/` folder
- Cover images in `music_covers/` folder
- Album covers in `music_album_covers/` folder

Files are served with signed URLs for secure access.

## Real-time Features

### Music Room Synchronization
- **Host Control**: Only room hosts can control playback
- **Auto-sync**: Automatic time synchronization every 5 seconds
- **Host Transfer**: Automatic host transfer when host disconnects
- **Activity Monitoring**: Connections timeout after 5 minutes of inactivity

### WebSocket Connection Management
- Heartbeat system for connection health
- Graceful disconnection handling
- Room state persistence in Redis cache
- Automatic cleanup of inactive rooms

## Deployment

### Google Cloud Run

1. **Build and push to Container Registry**
   ```bash
   gcloud builds submit --tag gcr.io/YOUR_PROJECT_ID/music-backend
   ```

2. **Deploy to Cloud Run**
   ```bash
   gcloud run deploy music-backend \
     --image gcr.io/YOUR_PROJECT_ID/music-backend \
     --platform managed \
     --region europe-west1 \
     --allow-unauthenticated
   ```

3. **Set environment variables in Cloud Run console**

### Environment Variables for Production

```env
DJANGO_SECRET_KEY=production-secret-key
DEBUG=False
DB_NAME=production-db
DB_USER=db-user
DB_PASSWORD=secure-password
DB_HOST=production-db-host
REDIS_URL=redis://production-redis:6379
FIREBASE_CREDENTIALS_JSON={"type":"service_account",...}
```

## Security Considerations

- CSRF protection enabled
- SSL redirect in production
- Secure cookies in production
- Token-based authentication
- File upload validation
- Rate limiting for anonymous users

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions, please open an issue in the repository or contact the development team.

---

**Note**: This is a backend API service. You'll need a frontend application to interact with these endpoints and WebSocket connections for a complete music streaming experience.
