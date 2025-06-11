import json
import asyncio
import time
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.db import database_sync_to_async
from django.core.cache import cache


class MusicRoomConsumer(AsyncWebsocketConsumer):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.room_name = None
        self.room_group_name = None
        self.user_id = None
        self.is_host = False
        
    async def connect(self):
        self.room_name = self.scope['url_route']['kwargs']['room_name']
        self.room_group_name = f"music_{self.room_name}"
        
       
        query_params = self.scope.get('query_string', b'').decode()
        self.user_id = self.extract_user_id(query_params)
        
    
        self.is_host = await self.check_or_assign_host()
     
        await self.channel_layer.group_add(self.room_group_name, self.channel_name)
        await self.accept()
        
        # Send initial room state to the connected user
        await self.send_room_state()
        
        # Notify other users about new participant
        await self.broadcast_user_joined()
        
        # Start clock sync for this room if not already started
        asyncio.create_task(self.start_room_clock())
    
    async def disconnect(self, close_code):
        # Remove user from room
        await self.remove_user_from_room()
        
        # Remove from channel group
        await self.channel_layer.group_discard(self.room_group_name, self.channel_name)
        
        # If host disconnects, transfer host to another user
        if self.is_host:
            await self.transfer_host_role()
    
    async def receive(self, text_data):
        try:
            data = json.loads(text_data)
            message_type = data.get('type')
            
            # Only host can send control messages
            if message_type in ['play', 'pause', 'seek', 'song_change'] and not self.is_host:
                await self.send_error("Only host can control playback")
                return
            
            if message_type == 'play':
                await self.handle_play(data)
            elif message_type == 'pause':
                await self.handle_pause(data)
            elif message_type == 'seek':
                await self.handle_seek(data)
            elif message_type == 'song_change':
                await self.handle_song_change(data)
            elif message_type == 'resume':
                await self.handle_resume(data)
            elif message_type == 'sync_request':
                await self.handle_sync_request()
            elif message_type == 'heartbeat':
                await self.handle_heartbeat(data)
            elif message_type=='leaveroom':
                await self.disconnect()
            
            
                
        except json.JSONDecodeError:
            await self.send_error("Invalid JSON format")
        except Exception as e:
            await self.send_error(f"Error processing message: {str(e)}")
    
    async def handle_play(self, data):
        """Handle play command from host"""
        server_time = time.time()
        
        # Update room state
        room_state = {
            'is_playing': True,
            'last_action_time': server_time,
            'current_position': data.get('position', 0),
            'song_url': data.get('song_url', ''),
            'song_name': data.get('song_name', ''),
            'artist_name': data.get('artist_name', ''),
            'cover_image': data.get('cover_image', ''),
        }
        
        await self.update_room_state(room_state)
        
        # Broadcast to all participants
        await self.channel_layer.group_send(
            self.room_group_name,
            {
                'type': 'music_control',
                'action': 'play',
                'server_timestamp': server_time,
                'position': room_state['current_position'],
                'song_data': {
                    'url': room_state['song_url'],
                    'name': room_state['song_name'],
                    'artist': room_state['artist_name'],
                    'cover': room_state['cover_image'],
                }
            }
        )
    
    async def handle_pause(self, data):
        """Handle pause command from host"""
        server_time = time.time()
        current_position = data.get('position', 0)
        
        # Update room state
        room_state = {
            'is_playing': False,
            'last_action_time': server_time,
            'current_position': current_position,
        }
        
        await self.update_room_state(room_state)
        
        # Broadcast to all participants
        await self.channel_layer.group_send(
            self.room_group_name,
            {
                'type': 'music_control',
                'action': 'pause',
                'server_timestamp': server_time,
                'position': current_position,
            }
        )

    
    async def handle_seek(self, data):
        """Handle seek command from host"""
        server_time = time.time()
        seek_position = data.get('position', 0)
        
        # Update room state
        room_state = {
            'last_action_time': server_time,
            'current_position': seek_position,
        }
        
        await self.update_room_state(room_state)
        
        # Broadcast to all participants
        await self.channel_layer.group_send(
            self.room_group_name,
            {
                'type': 'music_control',
                'action': 'seek',
                'server_timestamp': server_time,
                'position': seek_position,
            }
        )
    
    async def handle_song_change(self, data):
        """Handle song change from host"""
        server_time = time.time()
        
        # Update room state with new song
        room_state = {
            'song_url': data.get('song_url', ''),
            'song_name': data.get('song_name', ''),
            'artist_name': data.get('artist_name', ''),
            'cover_image': data.get('cover_image', ''),
            'current_position': 0,
            'last_action_time': server_time,
            'is_playing': data.get('auto_play', False),
        }
        
        await self.update_room_state(room_state)
        
        # Broadcast to all participants
        await self.channel_layer.group_send(
            self.room_group_name,
            {
                'type': 'music_control',
                'action': 'song_change',
                'server_timestamp': server_time,
                'song_data': {
                    'url': room_state['song_url'],
                    'name': room_state['song_name'],
                    'artist': room_state['artist_name'],
                    'cover': room_state['cover_image'],
                },
                'auto_play': room_state['is_playing'],
            }
        )
    
    async def handle_sync_request(self):
        """Handle sync request from participant"""
        room_state = await self.get_room_state()
        server_time = time.time()
        
        # Calculate current position if playing
        current_position = room_state.get('current_position', 0)
        if room_state.get('is_playing', False):
            elapsed_time = server_time - room_state.get('last_action_time', server_time)
            current_position += elapsed_time
        
        await self.send(text_data=json.dumps({
            'type': 'sync_response',
            'server_timestamp': server_time,
            'current_position': current_position,
            'is_playing': room_state.get('is_playing', False),
            'song_data': {
                'url': room_state.get('song_url', ''),
                'name': room_state.get('song_name', ''),
                'artist': room_state.get('artist_name', ''),
                'cover': room_state.get('cover_image', ''),
            }
        }))
    
    async def handle_heartbeat(self, data):
        """Handle heartbeat from participants"""
        client_time = data.get('client_timestamp', time.time())
        server_time = time.time()
        
        await self.send(text_data=json.dumps({
            'type': 'heartbeat_response',
            'server_timestamp': server_time,
            'client_timestamp': client_time,
            'latency': server_time - client_time,
        }))
    
    async def start_room_clock(self):
        """Start the room's master clock"""
        clock_key = f"room_clock_{self.room_name}"
        
        # Check if clock is already running
        if cache.get(clock_key):
            return
        
        # Mark clock as running
        cache.set(clock_key, True, timeout=3600)  # 1 hour timeout
        
        while True:
            try:
                # Send periodic time sync to all participants
                server_time = time.time()
                room_state = await self.get_room_state()
                
                # Calculate current position if playing
                current_position = room_state.get('current_position', 0)
                if room_state.get('is_playing', False):
                    elapsed_time = server_time - room_state.get('last_action_time', server_time)
                    current_position += elapsed_time
                
                await self.channel_layer.group_send(
                    self.room_group_name,
                    {
                        'type': 'time_sync',
                        'server_timestamp': server_time,
                        'current_position': current_position,
                        'is_playing': room_state.get('is_playing', False),
                    }
                )
                
                # Wait 5 seconds before next sync
                await asyncio.sleep(5)
                
            except Exception as e:
                print(f"Clock sync error: {e}")
                break
        
        # Remove clock marker
        cache.delete(clock_key)
    
    # WebSocket message handlers
    async def music_control(self, event):
        """Send music control message to WebSocket"""
        await self.send(text_data=json.dumps({
            'type': 'music_control',
            'action': event['action'],
            'server_timestamp': event['server_timestamp'],
            'position': event.get('position'),
            'song_data': event.get('song_data'),
            'auto_play': event.get('auto_play'),
        }))
    async def handle_resume(self, data):
        """Handle resume command from host"""
        server_time = time.time()
        current_position = data.get('position', 0)

        # Update room state
        room_state = {
            'is_playing': True,
            'last_action_time': server_time,
            'current_position': current_position,
        }

        await self.update_room_state(room_state)

        # Broadcast to all participants
        await self.channel_layer.group_send(
            self.room_group_name,
            {
                'type': 'music_control',
                'action': 'resume',
                'server_timestamp': server_time,
                'position': current_position,
            }
        )

    
    async def time_sync(self, event):
        """Send time sync message to WebSocket"""
        await self.send(text_data=json.dumps({
            'type': 'time_sync',
            'server_timestamp': event['server_timestamp'],
            'current_position': event['current_position'],
            'is_playing': event['is_playing'],
        }))
    
    async def user_joined(self, event):
        """Send user joined notification"""
        await self.send(text_data=json.dumps({
            'type': 'user_joined',
            'user_id': event['user_id'],
            'participants': event['participants'],
        }))
    
    async def user_left(self, event):
        """Send user left notification"""
        await self.send(text_data=json.dumps({
            'type': 'user_left',
            'user_id': event['user_id'],
            'participants': event['participants'],
        }))
    
    async def host_changed(self, event):
        """Send host changed notification"""
        await self.send(text_data=json.dumps({
            'type': 'host_changed',
            'new_host': event['new_host'],
        }))
    
    # Helper methods
    def extract_user_id(self, query_params):
        """Extract user_id from query parameters"""
        if 'user_id=' in query_params:
            return query_params.split('user_id=')[1].split('&')[0]
        return f"user_{int(time.time())}"  # Generate temporary user_id
    
    async def check_or_assign_host(self):
        """Check if user is host or assign host role"""
        room_key = f"room_{self.room_name}"
        room_data = cache.get(room_key, {})
        
        # If no host exists, make this user the host
        if not room_data.get('host_id'):
            room_data['host_id'] = self.user_id
            cache.set(room_key, room_data, timeout=3600)
            return True
        
        return room_data.get('host_id') == self.user_id
    
    async def get_room_state(self):
        """Get current room state"""
        room_key = f"room_{self.room_name}"
        return cache.get(room_key, {})
    
    async def update_room_state(self, updates):
        """Update room state"""
        room_key = f"room_{self.room_name}"
        room_data = cache.get(room_key, {})
        room_data.update(updates)
        cache.set(room_key, room_data, timeout=3600)
    
    async def send_room_state(self):
        """Send current room state to connected user"""
        room_state = await self.get_room_state()
        participants = room_state.get('participants', [])
        
        await self.send(text_data=json.dumps({
            'type': 'room_joined',
            'is_host': self.is_host,
            'participants': participants,
            'room_state': {
                'is_playing': room_state.get('is_playing', False),
                'current_position': room_state.get('current_position', 0),
                'song_data': {
                    'url': room_state.get('song_url', ''),
                    'name': room_state.get('song_name', ''),
                    'artist': room_state.get('artist_name', ''),
                    'cover': room_state.get('cover_image', ''),
                }
            }
        }))
    
    async def broadcast_user_joined(self):
        """Broadcast user joined message"""
        room_state = await self.get_room_state()
        participants = room_state.get('participants', [])
        
        if self.user_id not in participants:
            participants.append(self.user_id)
            await self.update_room_state({'participants': participants})
        
        await self.channel_layer.group_send(
            self.room_group_name,
            {
                'type': 'user_joined',
                'user_id': self.user_id,
                'participants': participants,
            }
        )
    
    async def remove_user_from_room(self):
        """Remove user from room participants"""
        room_state = await self.get_room_state()
        participants = room_state.get('participants', [])
        
        if self.user_id in participants:
            participants.remove(self.user_id)
            await self.update_room_state({'participants': participants})
        
        await self.channel_layer.group_send(
            self.room_group_name,
            {
                'type': 'user_left',
                'user_id': self.user_id,
                'participants': participants,
            }
        )
    
    async def transfer_host_role(self):
        """Transfer host role to another participant"""
        room_state = await self.get_room_state()
        participants = room_state.get('participants', [])
        
        # Remove current host from participants
        if self.user_id in participants:
            participants.remove(self.user_id)
        
        # Assign new host if participants exist
        if participants:
            new_host = participants[0]
            await self.update_room_state({
                'host_id': new_host,
                'participants': participants
            })
            
            await self.channel_layer.group_send(
                self.room_group_name,
                {
                    'type': 'host_changed',
                    'new_host': new_host,
                }
            )
        else:
            # Clear room if no participants left
            room_key = f"room_{self.room_name}"
            cache.delete(room_key)
    
    async def send_error(self, message):
        """Send error message to client"""
        await self.send(text_data=json.dumps({
            'type': 'error',
            'message': message,
        }))