import 'dart:async';
import 'package:flutter/material.dart';
import 'package:spotify_clone/music.dart';
import 'package:spotify_clone/Hive_History.dart';
import 'package:hive/hive.dart';
import 'package:spotify_clone/pages/room.dart';
import 'main_page.dart';

class Player_Music extends StatefulWidget {
  final String songName;
  final String artistName;
  final String url;
  final double timestamp;
  final String coverImage;
  final List Album;

  const Player_Music({
    super.key,
    this.songName = "Unknown Song",
    this.artistName = "Unknown Artist",
    this.coverImage = "",
    required this.url,
    this.timestamp = 0.00,
    this.Album = const [],
  });

  @override
  State<Player_Music> createState() => _Player_MusicState();
}

class _Player_MusicState extends State<Player_Music> {
  final _audioPlayer = Music(); // Singleton
  double _currentSliderValue = 0;
  double _volumeValue = 0.7;
  bool _isPlaying = false;
  bool _isFavorite = false;
  bool isHost = false;
    Duration? get duration => _audioPlayer.player.duration;
  Stream<Duration?> get durationStream => _audioPlayer.player.durationStream;

  StreamSubscription? _positionSub;
  StreamSubscription? _stateSub;

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

  @override
  void initState() {
    super.initState();
    isHost = _audioPlayer.isHost;

    _audioPlayer.stop();

    if (_audioPlayer.isHost) {
      _audioPlayer.changeSong(
        widget.url,
        songName: widget.songName,
        artistName: widget.artistName,
        coverImage: widget.coverImage,
        autoPlay: true,
      );
    } else {
      _audioPlayer.play(
        widget.url,
        position: Duration(seconds: widget.timestamp.toInt()),
        songName: widget.songName,
        artistName: widget.artistName,
        coverImage: widget.coverImage,
      );
    }

    var box = Hive.box<HiveHistory>('historyBox');
    bool exists = box.values.any((song) =>
        song.songName?.toLowerCase().trim() == widget.songName.toLowerCase().trim() &&
        song.artistName?.toLowerCase().trim() == widget.artistName.toLowerCase().trim());

    if (!exists) {
      box.add(HiveHistory(
        songName: widget.songName,
        artistName: widget.artistName,
        imageUrl: widget.coverImage,
        songUrl: widget.url,
        duration: widget.timestamp.toInt(),
      ));
    }

    _positionSub = _audioPlayer.positionStream.listen((position) {
      setState(() {
        _currentSliderValue = position.inSeconds.toDouble();
      });
    });

    _stateSub = _audioPlayer.stateStream.listen((state) {
      setState(() {
        _isPlaying = state.playing;
      });

      if (_isPlaying) {
        _startGradientAnimation();
      } else {
        _stopGradientAnimation();
      }
    });
  }

  @override
  void dispose() {
    _stopGradientAnimation();
    _positionSub?.cancel();
    _stateSub?.cancel();
    _audioPlayer.pause();
    super.dispose();
  }

  void _startGradientAnimation() {
    _gradientTimer?.cancel();
    _gradientTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_isPlaying) {
        setState(() {
          _currentGradientIndex = (_currentGradientIndex + 1) % _gradients.length;
        });
      }
    });
  }

  void _stopGradientAnimation() {
    _gradientTimer?.cancel();
  }

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString();
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final String songCoverUrl =
        widget.coverImage.isNotEmpty ? widget.coverImage : _audioPlayer.coverImage;
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
                minHeight: screenHeight -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () {
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            } else {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => const Main_Page()),
                              );
                            }
                          },
                          icon: const Icon(Icons.arrow_downward),
                        ),
                       
                      ],
                    ),
                    Column(
                      children: [
                        SizedBox(height: screenHeight * 0.02),
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
                        Column(
                          children: [
                            Text(
                              widget.songName,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.artistName,
                              style: const TextStyle(color: Colors.white54, fontSize: 18),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 15),
                            IconButton(
                              icon: Icon(
                                _isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: _isFavorite
                                    ? const Color.fromARGB(255, 225, 51, 51)
                                    : Colors.white54,
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
                                    _audioPlayer.seek(Duration(seconds: value.toInt()));
                                  });
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_formatTime(_currentSliderValue.toInt()),
                                      style: const TextStyle(color: Colors.white54)),
                                  Text(_formatTime(duration?.inSeconds ?? 0), style: TextStyle(color: Colors.white54)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            const Icon(Icons.shuffle, color: Colors.white54, size: 30),
                            const Icon(Icons.skip_previous, color: Colors.white, size: 40),
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
                            const Icon(Icons.skip_next, color: Colors.white, size: 40),
                            const Icon(Icons.sync_alt_rounded, color: Colors.white54, size: 30),
                          ],
                        ),
                      ],
                    ),
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
                                      _audioPlayer.setVolume(_volumeValue);
                                    });
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
}
