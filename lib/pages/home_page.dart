import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:spotify_clone/Hive_History.dart';
import 'package:hive/hive.dart';
import 'package:spotify_clone/pages/player.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Home_Page extends StatefulWidget {
  const Home_Page({super.key});

  @override
  State<Home_Page> createState() => _Home_PageState();
}

class _Home_PageState extends State<Home_Page> {
  List<Map<String, dynamic>> musicSuggestions = [];
  List<Map<String, dynamic>> explormusicSuggestions = [];
  List<Map<String, dynamic>> topAlbums = [];

  // ⚠️ Use emulator-safe localhost
  final String baseUrl = "http://localhost:8000";
  final Random _random = Random();

  void _changeGradient() {
    setState(() {});
  }

  // Get authentication token from SharedPreferences
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

  void loadExploreSuggestions() {
    final box = Hive.box<HiveHistory>('historyBox');
    final allEntries = box.values.toList();
    final recentEntries = allEntries.reversed.take(10).toSet();
    final exploreEntries =
        allEntries.where((song) => !recentEntries.contains(song)).toList();
    exploreEntries.shuffle();
    setState(() {
      explormusicSuggestions = exploreEntries
          .map((entry) => {
                'title': entry.songName ?? 'Unknown',
                'image': entry.imageUrl ?? '',
                'type': 'Explore',
                'url': entry.songUrl ?? '',
                'artistname': entry.artistName ?? 'Unknown',
              })
          .toList();
    });
  }

  void loadHiveSuggestions() {
    final box = Hive.box<HiveHistory>('historyBox');
    final entries = box.values.toList().reversed.take(10).toList();
    setState(() {
      musicSuggestions = entries
          .map((entry) => {
                'title': entry.songName ?? 'Unknown',
                'image': entry.imageUrl ?? '',
                'songurl': entry.songUrl ?? '',
                'type': 'History',
                'artistname': entry.artistName ?? 'Unknown',
              })
          .toList();
    });
  }

  // Updated fetchApi with authentication
  Future<List<dynamic>> fetchApi() async {
    try {
      final headers = await getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/album/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      } else if (response.statusCode == 401) {
        // Token expired or invalid - redirect to login
        _handleAuthError();
        throw Exception('Authentication failed');
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in fetchApi: $e');
      throw e;
    }
  }

  // Updated QuickPick with authentication
  Future<List<dynamic>> QuickPick() async {
    try {
      final headers = await getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/music/'), // Assuming this is the music endpoint
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      } else if (response.statusCode == 401) {
        _handleAuthError();
        throw Exception('Authentication failed');
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in QuickPick: $e');
      throw e;
    }
  }

  // Handle authentication errors
  void _handleAuthError() {
    // Clear stored token
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove('auth_token');
    });
    
    // Show error message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Session expired. Please login again.'),
        backgroundColor: Colors.red,
      ),
    );
    
    // Navigate to login page
    // Navigator.pushReplacementNamed(context, '/login');
  }

  void loadTopAlbums() async {
    try {
      final List<dynamic> albumsFromApi = await fetchApi();

      setState(() {
        topAlbums = albumsFromApi.map((album) {
          final songs = album['songs'] as List<dynamic>;
          final song = songs.isNotEmpty ? songs[0] : {};
          return {
            'title': album['name'] ?? 'Unknown Album',
            'image': album['cover_image'] ?? '',
            'type': album['artist'] ?? 'Unknown Artist',
          };
        }).toList();
      });
    } catch (e) {
      print("Error loading top albums: $e");
      // Show user-friendly error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load albums: ${e.toString()}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  // Load quick picks with authentication
  void loadQuickPick() async {
    try {
      final List<dynamic> quickPicks = await QuickPick();
      
      setState(() {
        // Update your quick picks data structure here
        // This depends on how you want to display quick picks
      });
    } catch (e) {
      print("Error loading quick picks: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load quick picks: ${e.toString()}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  // Check if user is authenticated on app start
  Future<void> checkAuthentication() async {
    final token = await getAuthToken();
    if (token == null) {
      // No token found, redirect to login
      // Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    // Verify token is still valid
    try {
      final headers = await getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/subscription-status/'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        _handleAuthError();
      }
    } catch (e) {
      print('Error checking authentication: $e');
      _handleAuthError();
    }
  }

  @override
  void initState() {
    super.initState();
    // Check authentication first
    checkAuthentication().then((_) {
      // Load data only if authenticated
      loadHiveSuggestions();
      loadExploreSuggestions();
      loadTopAlbums();
      loadQuickPick();
    });
    Future.delayed(const Duration(seconds: 1), _changeGradient);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(seconds: 2),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: ListView(
            physics: const BouncingScrollPhysics(),
            children: [
              const SizedBox(height: 70),
              _buildSectionTitle('Quick Picks'),
              const SizedBox(height: 15),
              _buildQuickPicks(),
              const SizedBox(height: 30),
              _buildSectionTitle('Top Genres'),
              const SizedBox(height: 15),
              _buildTopGenres(),
              const SizedBox(height: 30),
              _buildSectionTitle('Top Albums'),
              const SizedBox(height: 15),
              _TopAlbums(albums: topAlbums),
              const SizedBox(height: 30),
              _buildExploreGrid(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildQuickPicks() {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: musicSuggestions.length,
        itemBuilder: (context, index) {
          var item = musicSuggestions[index];
          return Container(
            width: 140,
            margin: const EdgeInsets.only(right: 12),
            child: _buildGlassCard(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Player_Music(
                                url: item['songurl'],
                                songName: item['title'],
                                coverImage: item['image'],
                                artistName: item['artistname'],
                                timestamp: 0.00,
                              ),
                            ),
                          );
                        },
                        child: item['image'] != null
                            ? Image.network(
                                item['image'],
                                height: 110,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.music_note,
                                        color: Colors.white, size: 60),
                              )
                            : const Icon(Icons.music_note,
                                color: Colors.white, size: 60),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item['title'],
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      item['type'],
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopGenres() {
    final genres = [
      {'title': 'Pop', 'icon': Icons.music_note},
      {'title': 'Rock', 'icon': Icons.waves},
      {'title': 'Jazz', 'icon': Icons.track_changes},
      {'title': 'Electronic', 'icon': Icons.speaker},
    ];

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.5,
      ),
      itemCount: genres.length,
      itemBuilder: (context, index) {
        var genre = genres[index];
        return _buildGlassCard(
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(genre['icon'] as IconData, color: Colors.white),
                const SizedBox(width: 10),
                Text(
                  genre['title'] as String,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExploreGrid() {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: explormusicSuggestions.length,
      itemBuilder: (context, index) {
        var item = explormusicSuggestions[index];
        return _buildGlassCard(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item['image'],
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item['title'],
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  item['type'],
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.1),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _TopAlbums extends StatefulWidget {
  final List<Map<String, dynamic>> albums;

  const _TopAlbums({required this.albums});

  @override
  __TopAlbumsState createState() => __TopAlbumsState();
}

class __TopAlbumsState extends State<_TopAlbums> {
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final pageCount = (widget.albums.length / 4).ceil();

    return Column(
      children: [
        SizedBox(
          height: 380,
          child: PageView.builder(
            itemCount: pageCount,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, pageIndex) {
              final startIndex = pageIndex * 4;
              final endIndex = (startIndex + 4 > widget.albums.length)
                  ? widget.albums.length
                  : startIndex + 4;
              final items = widget.albums.sublist(startIndex, endIndex);

              return GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  var item = items[index];
                  return _buildGlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                item['image'],
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.broken_image,
                                        color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item['title'],
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            item['type'],
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        _buildDotIndicator(pageCount),
      ],
    );
  }

  Widget _buildDotIndicator(int pageCount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pageCount, (index) {
        return Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentPage == index ? Colors.white : Colors.white54,
          ),
        );
      }),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.1),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}