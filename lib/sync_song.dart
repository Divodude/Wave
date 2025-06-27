import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class SyncSong {
  final String roomid;
  WebSocketChannel? channel;

  SyncSong({required this.roomid});

  void SyncSong_build({
    required Function(Map<String, dynamic>) onTimeSync,
    Function(Map<String, dynamic>)? onMusicControl,
    Function(Map<String, dynamic>)? onRoomJoined,
    Function(String)? onError,
  }) {
    final String url = 'ws://api-1039005314066.europe-west1.run.app/ws/music/$roomid/';

    try {
      channel = WebSocketChannel.connect(Uri.parse(url));

      channel!.stream.listen(
        (message) {
          print('Raw message: $message');

          try {
            final data = jsonDecode(message);

            switch (data['type']) {
              case 'room_joined':
                if (onRoomJoined != null) onRoomJoined(data);
                break;

              case 'time_sync':
                onTimeSync({
                  'server_timestamp': data['server_timestamp'],
                  'current_position': data['current_position'],
                  'is_playing': data['is_playing'],
                });
                break;

              case 'music_control':
                if (onMusicControl != null) onMusicControl(data);
                break;

              case 'error':
                onError?.call(data['message'] ?? 'Unknown error');
                break;

              default:
                print('Unhandled message type: ${data['type']}');
            }
          } catch (e) {
            onError?.call('❌ Error parsing message: $e');
          }
        },
        onError: (error) {
          onError?.call('WebSocket error: $error');
        },
        onDone: () {
          print('🔌 WebSocket connection closed.');
        },
      );
    } catch (e) {
      onError?.call('Failed to connect to WebSocket: $e');
    }
  }

  void send(String message) {
    if (channel != null) {
      channel!.sink.add(message);
      print('📤 Message sent: $message');
    } else {
      print('⚠️ WebSocket channel is not initialized.');
    }
  }

  void close() {
    channel?.sink.close();
    print('🔌 WebSocket connection closed by client.');
  }






  
}
