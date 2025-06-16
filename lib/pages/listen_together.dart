import 'dart:convert';
import 'package:spotify_clone/sync_song.dart';
import 'package:spotify_clone/music.dart';

class SyncAdapter {
  final Music music = Music();
  late SyncSong _syncSong;
  String roomId;
  bool isHost = false;

  final void Function(String info)? onInfo;
  final void Function(String songInfo)? onSongInfo;

  SyncAdapter({
    required this.roomId,
    this.onInfo,
    this.onSongInfo,
  }) {
    _syncSong = SyncSong(roomid: roomId);
  }

  void joinRoom(String newRoomId) {
    roomId = newRoomId;
    _syncSong = SyncSong(roomid: roomId);
    startListening();
  }

  void startListening() {
    _syncSong.SyncSong_build(
      onRoomJoined: (data) {
        isHost = data['is_host'];
        onInfo?.call('Joined room. Host: $isHost');
      },
      onTimeSync: (data) {
        onInfo?.call(
          '⏱️ Time: ${data['server_timestamp']}\n'
          '🎵 Position: ${data['current_position'].toStringAsFixed(2)} sec\n'
          '▶️ Playing: ${data['is_playing']}',
        );
      },
      onMusicControl: (data) {
        final song = data['song_data'] ?? {};
        final action = data['action'];
        onSongInfo?.call(
          '🎵 Now Playing: ${song['name'] ?? "Unknown"}\n'
          '👤 Artist: ${song['artist'] ?? "Unknown"}\n'
          '🎬 Action: $action',
        );

        if (action == 'play') {
          music.play(song['url'], position: Duration(seconds: (data['position'] ?? 0).toInt()));
        } else if (action == 'pause') {
          music.pause();
        } else if (action == 'seek') {
          music.seek(Duration(seconds: (data['position'] ?? 0).toInt()));
        }
      },
      onError: (error) {
        onInfo?.call('❌ Error: $error');
      },
    );
  }

  void sendPlay({
    required String url,
    required String name,
    required String artist,
    required String coverImage,
    Duration position = Duration.zero,
  }) {
    if (!isHost) {
      onInfo?.call("❗ You are not the host. Can't control playback.");
      return;
    }

    final data = {
      "type": "play",
      "position": position.inSeconds.toDouble(),
      "song_url": url,
      "song_name": name,
      "artist_name": artist,
      "cover_image": coverImage,
    };

    _syncSong.send(json.encode(data));
    music.play(url, position: position);
  }

  void sendPause() {
    if (!isHost) {
      onInfo?.call("❗ Only host can pause.");
      return;
    }

    _syncSong.send(json.encode({
      "type": "pause",
      "position": music.currentPosition.inSeconds.toDouble(),
    }));
    music.pause();
  }

  void sendSeek(double seconds) {
    if (!isHost) {
      onInfo?.call("❗ Only host can seek.");
      return;
    }

    _syncSong.send(json.encode({
      "type": "seek",
      "position": seconds,
    }));
    music.seek(Duration(seconds: seconds.toInt()));
  }

  void leaveRoom() {
    _syncSong.close();
    onInfo?.call("👋 Left the room.");
    onSongInfo?.call("No song playing");
  }

  void dispose() {
    _syncSong.close();
  }
}
