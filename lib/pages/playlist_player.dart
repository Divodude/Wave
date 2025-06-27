import 'dart:async';
import 'package:flutter/material.dart';
import 'package:spotify_clone/music.dart';
import 'package:spotify_clone/Hive_History.dart';
import 'package:hive/hive.dart';

import 'dart:math'; // Add this import for Random
class PlaylistPlayer extends StatefulWidget {
  final List<Map<String, dynamic>> playlist;
  final int initialIndex;
  final String playlistName;

  const PlaylistPlayer({
    super.key,
    required this.playlist,
    this.initialIndex = 0,
    this.playlistName = "Playlist",
  });

  @override
  State<PlaylistPlayer> createState() => _PlaylistPlayerState();
}

class _PlaylistPlayerState extends State<PlaylistPlayer> {
  final _audioPlayer = Music();
  double _currentSliderValue = 0;
  double _volumeValue = 0.7;
  bool _isPlaying = false;
  bool _isFavorite = false;
  bool _isShuffled = false;
  bool _isRepeat = false;
  int _currentSongIndex = 0;
  bool isHost = false;
  late Map<String, dynamic> _currentSong;

  // Gradient animation
  final List<List<Color>> _gradients = [
    [Colors.deepPurple, Colors.blue],
    [Colors.blue, Colors.green],
    [Colors.green, Colors.yellow],
    [Colors.yellow, Colors.orange],
    [Colors.orange, Colors.red],
    [Colors.red, Colors.purple],
  ];
  int _currentGradientIndex = 0;
  Timer? _gradientTimer;
  StreamSubscription? _positionSub;
  StreamSubscription? _stateSub;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    isHost = _audioPlayer.isHost;
  }

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  void _initializePlayer() {
    if (widget.playlist.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This playlist has no songs')),
        );
        Navigator.pop(context);
      });
      return;
    }

    _currentSongIndex = widget.initialIndex.clamp(0, widget.playlist.length - 1);
    _currentSong = widget.playlist[_currentSongIndex];

    _playCurrentSong();

    _positionSub = _audioPlayer.positionStream.listen((position) {
      if (mounted) {
        setState(() {
          _currentSliderValue = position.inSeconds.toDouble();
        });
      }
    });

    _stateSub = _audioPlayer.stateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = _audioPlayer.isPlaying;
        });

        if (state.playing) {
          _startGradientAnimation();
        } else {
          _stopGradientAnimation();
        }
      }
    });
  }

  void _playCurrentSong() {
    if (_currentSong['url'] == null || _currentSong['url'].isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid song URL')),
      );
      return;
    }

    _audioPlayer.stop();

    if (isHost) {
      _audioPlayer.changeSong(
        _currentSong['url'],
        songName: _currentSong['songName'] ?? 'Unknown Song',
        artistName: _currentSong['artistName'] ?? 'Unknown Artist',
        coverImage: _currentSong['coverImage'] ?? '',
        autoPlay: true,
      );
    } else {
      _audioPlayer.play(
        _currentSong['url'],
        position: Duration(seconds: (_currentSong['timestamp'] ?? 0.0).toInt()),
        songName: _currentSong['songName'] ?? 'Unknown Song',
        artistName: _currentSong['artistName'] ?? 'Unknown Artist',
        coverImage: _currentSong['coverImage'] ?? '',
      );
    }

    _addToHistory(_currentSong);
  }

  void _addToHistory(Map<String, dynamic> song) {
    final box = Hive.box<HiveHistory>('historyBox');
    
    bool exists = box.values.any((historyItem) =>
      historyItem.songName?.toLowerCase().trim() == song['songName']?.toString().toLowerCase().trim() &&
      historyItem.artistName?.toLowerCase().trim() == song['artistName']?.toString().toLowerCase().trim()
    );

    if (!exists) {
      box.add(HiveHistory(
        songName: song['songName']?.toString() ?? 'Unknown Song',
        artistName: song['artistName']?.toString() ?? 'Unknown Artist',
        imageUrl: song['coverImage']?.toString() ?? '',
        songUrl: song['url']?.toString() ?? '',
        duration: (song['timestamp'] ?? 0.0).toInt(),
      ));
    }
  }

  void _startGradientAnimation() {
    _gradientTimer?.cancel();
    _gradientTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_isPlaying && mounted) {
        setState(() {
          _currentGradientIndex = (_currentGradientIndex + 1) % _gradients.length;
        });
      }
    });
  }

  void _stopGradientAnimation() {
    _gradientTimer?.cancel();
  }

  void _playNextSong() {
    if (widget.playlist.isEmpty) return;

    if (_isShuffled) {
      _currentSongIndex = Random().nextInt(widget.playlist.length);
    } else {
      _currentSongIndex = (_currentSongIndex + 1) % widget.playlist.length;
    }
    _changeSong();
  }

  void _playPreviousSong() {
    if (widget.playlist.isEmpty) return;

    if (_isShuffled) {
      _currentSongIndex = Random().nextInt(widget.playlist.length);
    } else {
      _currentSongIndex = (_currentSongIndex - 1 + widget.playlist.length) % widget.playlist.length;
    }
    _changeSong();
  }

  void _changeSong() {
    _currentSongIndex = _currentSongIndex.clamp(0, widget.playlist.length - 1);
    _currentSong = widget.playlist[_currentSongIndex];
    _playCurrentSong();

    if (mounted) {
      setState(() {
        _currentSliderValue = 0;
        _isFavorite = false;
      });
    }
  }

  void _showPlaylist() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(
                    widget.playlistName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: widget.playlist.length,
                itemBuilder: (context, index) {
                  final song = widget.playlist[index];
                  final isCurrentSong = index == _currentSongIndex;
                  
                  return ListTile(
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        image: DecorationImage(
                          image: NetworkImage(song['coverImage']?.toString() ?? ''),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    title: Text(
                      song['songName']?.toString() ?? 'Unknown Song',
                      style: TextStyle(
                        color: isCurrentSong ? Colors.blue : Colors.white,
                        fontWeight: isCurrentSong ? FontWeight.bold : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      song['artistName']?.toString() ?? 'Unknown Artist',
                      style: TextStyle(
                        color: isCurrentSong ? Colors.blue.shade300 : Colors.white54,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: isCurrentSong
                        ? Icon(
                            _isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.blue,
                          )
                        : null,
                    onTap: () {
                      setState(() {
                        _currentSongIndex = index;
                      });
                      _changeSong();
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _stopGradientAnimation();
    _positionSub?.cancel();
    _stateSub?.cancel();
    _audioPlayer.pause();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String songCoverUrl = (_currentSong['coverImage']?.toString() ?? '').isNotEmpty
        ? _currentSong['coverImage'].toString()
        : _audioPlayer.coverImage;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final albumArtSize = screenWidth * 0.7 > 300 ? 300.0 : screenWidth * 0.7;
    
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(seconds: 2),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _gradients[_currentGradientIndex],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: screenHeight - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_downward, color: Colors.white),
                        ),
                        Column(
                          children: [
                            Text(
                              widget.playlistName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${_currentSongIndex + 1} of ${widget.playlist.length}',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: _showPlaylist,
                              icon: const Icon(Icons.queue_music, color: Colors.white),
                            ),
                            
                          ],
                        ),
                      ],
                    ),

                    // Main Content
                    Column(
                      children: [
                        SizedBox(height: screenHeight * 0.02),

                        // Album Art
                        Center(
                          child: Container(
                            width: albumArtSize,
                            height: albumArtSize,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              image: DecorationImage(
                                image: NetworkImage(songCoverUrl),
                                fit: BoxFit.cover,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.5),
                                  spreadRadius: 5,
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                )
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.03),

                        // Song Info
                        Column(
                          children: [
                            Text(
                              _currentSong['songName']?.toString() ?? 'Unknown Song',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _currentSong['artistName']?.toString() ?? 'Unknown Artist',
                              style: const TextStyle(
                                color: Colors.white54, 
                                fontSize: 18,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 15),
                            IconButton(
                              icon: Icon(
                                _isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: _isFavorite ? const Color.fromARGB(255, 225, 51, 51) : Colors.white54,
                                size: 30,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isFavorite = !_isFavorite;
                                });
                              },
                            ),
                          ],
                        ),

                        SizedBox(height: screenHeight * 0.02),

                        // Progress Bar
                        Column(
                          children: [
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: Colors.blue,
                                inactiveTrackColor: Colors.white24,
                                thumbColor: Colors.white,
                              ),
                              child: Slider(
                                value: _currentSliderValue,
                                min: 0,
                                max: 210,
                                onChanged: (value) {
                                  setState(() {
                                    _currentSliderValue = value;
                                  });
                                  _audioPlayer.seek(Duration(seconds: value.toInt()));
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatTime(_currentSliderValue.toInt()),
                                    style: const TextStyle(color: Colors.white54),
                                  ),
                                  const Text(
                                    '3:30',
                                    style: TextStyle(color: Colors.white54),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: screenHeight * 0.02),

                        // Controls
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _isShuffled = !_isShuffled;
                                });
                              },
                              icon: Icon(
                                Icons.shuffle,
                                color: _isShuffled ? Colors.blue : Colors.white54,
                                size: 30,
                              ),
                            ),
                            IconButton(
                              onPressed: _playPreviousSong,
                              icon: const Icon(
                                Icons.skip_previous,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (_isPlaying) {
                                    _audioPlayer.pause();
                                    _stopGradientAnimation();
                                  } else {
                                    _audioPlayer.resume();
                                    _startGradientAnimation();
                                  }
                                  _isPlaying = !_isPlaying;
                                });
                              },
                              child: Container(
                                width: 70,
                                height: 70,
                                decoration: const BoxDecoration(
                                  color: Color.fromARGB(255, 1, 75, 106),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _isPlaying ? Icons.pause : Icons.play_arrow,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: _playNextSong,
                              icon: const Icon(
                                Icons.skip_next,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _isRepeat = !_isRepeat;
                                });
                              },
                              icon: Icon(
                                _isRepeat ? Icons.repeat_one : Icons.repeat,
                                color: _isRepeat ? Colors.blue : Colors.white54,
                                size: 30,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Bottom Volume Control
                    Column(
                      children: [
                        SizedBox(height: screenHeight * 0.02),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            const Icon(Icons.volume_up, color: Colors.white54),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: Colors.white,
                                  inactiveTrackColor: Colors.white24,
                                  thumbColor: Colors.white,
                                ),
                                child: Slider(
                                  value: _volumeValue,
                                  onChanged: (value) {
                                    setState(() {
                                      _volumeValue = value;
                                    });
                                    _audioPlayer.setVolume(_volumeValue);
                                  },
                                ),
                              ),
                            ),
                            const Icon(Icons.connected_tv, color: Colors.white54),
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(1, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }
}