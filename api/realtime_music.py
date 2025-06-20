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
        self._clock_task = None
        self.last_activity = time.time()
        
    async def connect(self):
        self.room_name = self.scope['url_route']['kwargs']['room_name']
        self.room_group_name = f"music_{self.room_name}"
        
        query_params = self.scope.get('query_string', b'').decode()
        self.user_id = self.extract_user_id(query_params)
        
        self.is_host = await self.check_or_assign_host()
     
        await self.channel_layer.group_add(self.room_group_name, self.channel_name)
        await self.accept()
        
        await self.send_room_state()
        await self.broadcast_user_joined()
        
        self._clock_task = asyncio.create_task(self.start_room_clock())
        asyncio.create_task(self.monitor_activity())
    
    async def disconnect(self, close_code):
        # Cancel running tasks
        if self._clock_task and not self._clock_task.done():
            self._clock_task.cancel()
            try:
                await self._clock_task
            except asyncio.CancelledError:
                pass
        
        # Clean up clock key if we own it
        clock_key = f"room_clock_{self.room_name}"
        if cache.get(clock_key) == self.channel_name:
            cache.delete(clock_key)
        
        # Standard cleanup
        await self.remove_user_from_room()
        await self.channel_layer.group_discard(self.room_group_name, self.channel_name)
        
        if self.is_host:
            await self.transfer_host_role()

    async def monitor_activity(self):
        """Close connection after 5 minutes of inactivity"""
        try:
            while True:
                await asyncio.sleep(30)
                if time.time() - self.last_activity > 300:  # 5 minutes
                    await self.close()
                    break
        except Exception as e:
            print(f"Activity monitor error: {e}")

    async def receive(self, text_data):
        self.last_activity = time.time()
        try:
            data = json.loads(text_data)
            message_type = data.get('type')
            
            if message_type in ['play', 'pause', 'seek', 'song_change'] and not self.is_host:
                await self.send_error("Only host can control playback")
                return
            
            handler = getattr(self, f'handle_{message_type}', None)
            if handler:
                await handler(data)
            else:
                await self.send_error(f"Unknown message type: {message_type}")
                
        except json.JSONDecodeError:
            await self.send_error("Invalid JSON format")
        except Exception as e:
            await self.send_error(f"Error processing message: {str(e)}")

    async def start_room_clock(self):
        """Room clock with proper cleanup handling"""
        clock_key = f"room_clock_{self.room_name}"
        
        # Atomically set the clock key if not exists
        if not cache.add(clock_key, self.channel_name, timeout=3600):
            return  # Another instance is already handling the clock
            
        try:
            while True:
                if self.websocket_close_code is not None:
                    break
                    
                server_time = time.time()
                room_state = await self.get_room_state()
                
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
                
                # Break sleep into chunks to check for disconnection
                for _ in range(5):
                    if self.websocket_close_code is not None:
                        break
                    await asyncio.sleep(1)
                    
        except asyncio.CancelledError:
            pass  # Task was cancelled during disconnect
        except Exception as e:
            print(f"Clock error: {e}")
        finally:
            # Only clean up if we're still the owner
            if cache.get(clock_key) == self.channel_name:
                cache.delete(clock_key)

    # Message handlers
    async def handle_play(self, data):
        server_time = time.time()
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
        server_time = time.time()
        room_state = {
            'is_playing': False,
            'last_action_time': server_time,
            'current_position': data.get('position', 0),
        }
        
        await self.update_room_state(room_state)
        
        await self.channel_layer.group_send(
            self.room_group_name,
            {
                'type': 'music_control',
                'action': 'pause',
                'server_timestamp': server_time,
                'position': room_state['current_position'],
            }
        )

    async def handle_seek(self, data):
        server_time = time.time()
        room_state = {
            'last_action_time': server_time,
            'current_position': data.get('position', 0),
        }
        
        await self.update_room_state(room_state)
        
        await self.channel_layer.group_send(
            self.room_group_name,
            {
                'type': 'music_control',
                'action': 'seek',
                'server_timestamp': server_time,
                'position': room_state['current_position'],
            }
        )

    async def handle_song_change(self, data):
        server_time = time.time()
        song_data = data.get('song_data', {})
        
        room_state = {
            'song_url': song_data.get('url', ''),
            'song_name': song_data.get('name', ''),
            'artist_name': song_data.get('artist', ''),
            'cover_image': song_data.get('song_cover', song_data.get('cover', '')),
            'current_position': 0,
            'last_action_time': server_time,
            'is_playing': data.get('auto_play', False),
        }
        
        await self.update_room_state(room_state)
        
        await self.channel_layer.group_send(
            self.room_group_name,
            {
                'type': 'music_control',
                'action': 'song_change',
                'server_timestamp': server_time,
                'position': 0,
                'song_data': {
                    'url': room_state['song_url'],
                    'name': room_state['song_name'],
                    'artist': room_state['artist_name'],
                    'cover': room_state['cover_image'],
                },
                'auto_play': room_state['is_playing'],
            }
        )

    async def handle_resume(self, data):
        server_time = time.time()
        room_state = {
            'is_playing': True,
            'last_action_time': server_time,
            'current_position': data.get('position', 0),
        }

        await self.update_room_state(room_state)

        await self.channel_layer.group_send(
            self.room_group_name,
            {
                'type': 'music_control',
                'action': 'resume',
                'server_timestamp': server_time,
                'position': room_state['current_position'],
            }
        )

    async def handle_sync_request(self):
        room_state = await self.get_room_state()
        server_time = time.time()
        
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
        client_time = data.get('client_timestamp', time.time())
        server_time = time.time()
        
        await self.send(text_data=json.dumps({
            'type': 'heartbeat_response',
            'server_timestamp': server_time,
            'client_timestamp': client_time,
            'latency': server_time - client_time,
        }))

    # WebSocket message handlers
    async def music_control(self, event):
        await self.send(text_data=json.dumps({
            'type': 'music_control',
            'action': event['action'],
            'server_timestamp': event['server_timestamp'],
            'position': event.get('position'),
            'song_data': event.get('song_data'),
            'auto_play': event.get('auto_play'),
        }))

    async def time_sync(self, event):
        await self.send(text_data=json.dumps({
            'type': 'time_sync',
            'server_timestamp': event['server_timestamp'],
            'current_position': event['current_position'],
            'is_playing': event['is_playing'],
        }))

    async def user_joined(self, event):
        await self.send(text_data=json.dumps({
            'type': 'user_joined',
            'user_id': event['user_id'],
            'participants': event['participants'],
        }))

    async def user_left(self, event):
        await self.send(text_data=json.dumps({
            'type': 'user_left',
            'user_id': event['user_id'],
            'participants': event['participants'],
        }))

    async def host_changed(self, event):
        await self.send(text_data=json.dumps({
            'type': 'host_changed',
            'new_host': event['new_host'],
        }))

    # Helper methods
    def extract_user_id(self, query_params):
        if 'user_id=' in query_params:
            return query_params.split('user_id=')[1].split('&')[0]
        return f"user_{int(time.time())}"

    async def check_or_assign_host(self):
        room_key = f"room_{self.room_name}"
        room_data = cache.get(room_key, {})
        
        if not room_data.get('host_id'):
            room_data['host_id'] = self.user_id
            cache.set(room_key, room_data, timeout=3600)
            return True
        
        return room_data.get('host_id') == self.user_id

    async def get_room_state(self):
        room_key = f"room_{self.room_name}"
        return cache.get(room_key, {})

    async def update_room_state(self, updates):
        room_key = f"room_{self.room_name}"
        room_data = cache.get(room_key, {})
        room_data.update(updates)
        cache.set(room_key, room_data, timeout=3600)

    async def send_room_state(self):
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
        room_state = await self.get_room_state()
        participants = room_state.get('participants', [])
        
        if self.user_id in participants:
            participants.remove(self.user_id)
        
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
            room_key = f"room_{self.room_name}"
            cache.delete(room_key)

    async def send_error(self, message):
        await self.send(text_data=json.dumps({
            'type': 'error',
            'message': message,
        }))