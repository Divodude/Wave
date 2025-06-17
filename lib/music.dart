import 'dart:convert';
import 'package:just_audio/just_audio.dart';
import 'package:spotify_clone/sync_song.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class Music {
  static final Music _instance = Music._internal();
  factory Music() => _instance;
  Music._internal() {
    player.positionStream.listen((pos) {
      _cachedPosition = pos;
    });
  }

  final AudioPlayer player = AudioPlayer();
  Duration _cachedPosition = Duration.zero;

  bool isHost = false;
  bool is_syncing = false;

  SyncSong? sync;

  // Metadata fields
  String? currentSongName;
  String? currentArtistName;
  String? currentCoverImage;
  String? currentSongUrl;

  // Getters for metadata
  String get songName => currentSongName ?? "Unknown";
  String get artistName => currentArtistName ?? "Unknown";
  String get coverImage => currentCoverImage ?? "";
  String get songUrl => currentSongUrl ?? "";

  /// Initialize the sync adapter (usually called when user joins room)
  void initSync(String roomId) {
    is_syncing = true;

    sync = SyncSong(roomid: roomId);
    sync!.SyncSong_build(
      onRoomJoined: (data) {
        isHost = data['is_host'] ?? false;
      },
      onTimeSync: (data) {},
      onMusicControl: (data) {
        if (!isHost) {
          final song = data['song_data'];
          final action = data['action'];
          final position = Duration(seconds: (data['position'] ?? 0).toInt());

          if (action == 'play') {
            _syncPlay(song['url'], position: position, song: song);
          } else if (action == 'pause') {
            _syncSeek(position);
            _syncPause();
          } else if (action == 'seek') {
            _syncSeek(position);
          } else if (action == 'resume') {
            _syncSeek(position);
            _syncResume();
          } else if (action == 'song_change') {
            _syncSongChange(song, data['auto_play'] ?? false);
          }
        }
      },
      onError: (e) {
        is_syncing = false;
        print("Sync error: $e");
      },
    );
  }



Future<bool> subscribeUserOnline({String plan = 'Premium'}) async {
  final headers = await getAuthHeaders();

  try {
    final response = await http.post(
      Uri.parse('http://127.0.0.1:8000/subscribe/'),
      headers: headers,
      body: jsonEncode({'plan_name': plan}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final body = json.decode(response.body);
      print("Subscription activated: $body");

      // Optionally store status locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_subscribed', true);

      return true;
    } else {
      print("Subscription failed: ${response.body}");
      return false;
    }
  } catch (e) {
    print("Subscription error: $e");
    return false;
  }
}


  Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Create authenticated headers
  Future<Map<String, String>> getAuthHeaders() async {
    final token = await getAuthToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Token $token',
    };
  }





  Future<bool> checkSubscriptionStatus() async {
  final headers = await getAuthHeaders();

  try {
    final response = await http.get(
      Uri.parse('http://127.0.0.1:8000/subscription-status/'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['subscribed'] == true;
    } else {
      print("Failed to check subscription: ${response.statusCode}");
      return false;
    }
  } catch (e) {
    print("Subscription status error: $e");
    return false;
  }
}


  // Private sync methods to avoid infinite loops
  Future<void> _syncPlay(String url, {Duration? position, Map<String, dynamic>? song}) async {
    await player.stop();
    await player.setUrl(url);
    if (position != null) await player.seek(position);
    await player.play();

    if (song != null) {
      currentSongUrl = url;
      currentSongName = song['name'] ?? "Unknown";
      currentArtistName = song['artist'] ?? "Unknown";
      currentCoverImage = song['song_cover'] ?? "";
    }
  }

  void _syncPause() {
    player.pause();
  }

  void _syncSeek(Duration pos) {
    player.seek(pos);
  }

  void _syncResume() {
    player.play();
  }

  Future<void> _syncSongChange(Map<String, dynamic> song, bool autoPlay) async {
    currentSongUrl = song['url'];
    currentSongName = song['name'] ?? 'Unknown';
    currentArtistName = song['artist'] ?? 'Unknown';
    currentCoverImage = song['song_cover'] ?? '';

    await player.stop();
    await player.setUrl(currentSongUrl!);
    await player.seek(Duration.zero);

    if (autoPlay) {
      await player.play();
    }
  }

  // Public methods for host control
  Future<void> play(String url,
      {Duration? position, String? songName, String? artistName, String? coverImage}) async {
    await player.stop();
    await player.setUrl(url);
    if (position != null) await player.seek(position);
    await player.play();

    // Store metadata
    currentSongName = songName ?? "Unknown";
    currentArtistName = artistName ?? "Unknown";
    currentCoverImage = coverImage ?? "";
    currentSongUrl = url;

    if (isHost && sync != null) {
      sync!.send(json.encode({
        "type": "music_control",
        "action": "play",
        "position": (position ?? Duration.zero).inSeconds.toDouble(),
        "song_data": {
          "url": url,
          "name": currentSongName,
          "artist": currentArtistName,
          "song_cover": currentCoverImage
        }
      }));
    }
  }
Future<void> changeSong(String url,
    {String? songName, String? artistName, String? coverImage, bool autoPlay = false}) async {
  currentSongName = songName ?? "Unknown";
  currentArtistName = artistName ?? "Unknown";
  currentCoverImage = coverImage ?? "";
  currentSongUrl = url;
  
  await player.stop();
  await player.setUrl(url);

  if (isHost && sync != null) {
    sync!.send(json.encode({
      "type": "song_change",
      "song_data": {
        "url": currentSongUrl,
        "name": currentSongName,
        "artist": currentArtistName,
        "cover": currentCoverImage,  // Changed from song_cover to cover for consistency
      },
      "auto_play": autoPlay,
      "position": 0
    }));
  }

  await player.seek(Duration.zero);

  if (autoPlay) {
    await player.play();
  }
}

  void pause() {
    if (isHost && sync != null) {
      sync!.send(json.encode({
        "type": "pause",
        "position": currentPosition.inSeconds.toDouble(),
      }));
    }
    player.pause();
  }

  void seek(Duration pos) {
    if (isHost && sync != null) {
      sync!.send(json.encode({
        "type": "seek",
        "position": pos.inSeconds.toDouble(),
      }));
    }
    player.seek(pos);
  }

  void resume() {
    if (isHost && sync != null) {
      sync!.send(json.encode({
        "type": "resume",
        "position": currentPosition.inSeconds.toDouble(),
      }));
    }
    player.play();
  }

  void toggle() => player.playing ? pause() : resume();

  bool get isPlaying => player.playing;
  Stream<Duration> get positionStream => player.positionStream;
  Stream<PlayerState> get stateStream => player.playerStateStream;
  Duration get currentPosition => _cachedPosition;

  void setVolume(double v) => player.setVolume(v);

  void stop() => player.stop();

  void closeSync() {
    if (sync != null) {
      sync!.close();
      sync = null;
    }
    is_syncing = false;
    isHost = false;
  }
}
