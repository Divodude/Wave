import 'dart:math';
import 'package:flutter/material.dart';

class Library_Page extends StatefulWidget {
  const Library_Page({super.key});

  @override
  State<Library_Page> createState() => _Library_PageState();
}

class _Library_PageState extends State<Library_Page> {
  final List<Map<String, dynamic>> categories = [
    {
      'title': 'Top Picks',
      'icon': Icons.star,
      'color': Colors.amber,
    },
    {
      'title': 'Trending',
      'icon': Icons.trending_up,
      'color': Colors.red,
    },
    {
      'title': 'New Release',
      'icon': Icons.new_releases,
      'color': Colors.green,
    },
    {
      'title': 'Discover',
      'icon': Icons.explore,
      'color': Colors.blue,
    },
  ];

  final List<Map<String, dynamic>> userContent = [
    {
      'title': 'Liked Videos',
      'subtitle': '47 songs',
      'icon': Icons.favorite,
      'image': 'https://i.ytimg.com/vi/5qap5aO4i9A/hqdefault.jpg',
    },
    {
      'title': 'History',
      'subtitle': 'Recently played',
      'icon': Icons.history,
      'image': 'https://i.ytimg.com/vi/3AtDnEC4zak/hqdefault.jpg',
    },
    {
      'title': 'My Playlists',
      'subtitle': '12 playlists',
      'icon': Icons.queue_music,
      'image': 'https://i.ytimg.com/vi/jfKfPfyJRdk/hqdefault.jpg',
    },
    {
      'title': 'Downloaded',
      'subtitle': '23 songs offline',
      'icon': Icons.download_done,
      'image': 'https://i.ytimg.com/vi/rUxyKA_-grg/hqdefault.jpg',
    },
  ];

  List<Color> _gradientColors = [Colors.deepPurple, Colors.indigo];
  final Random _random = Random();

  void _changeGradient() {
    setState(() {
      _gradientColors = [
        Color.fromRGBO(_random.nextInt(256), _random.nextInt(256), _random.nextInt(256), 1),
        Color.fromRGBO(_random.nextInt(256), _random.nextInt(256), _random.nextInt(256), 1),
      ];
    });
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 1), _changeGradient);
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
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedContainer(
        duration: Duration(seconds: 2),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: ListView(
            physics: BouncingScrollPhysics(),
            children: [
              const SizedBox(height: 70),
              Text(
                'Your Library',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 25),
              
              // Category Grid
              GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.5,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  var category = categories[index];
                  return _buildGlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            category['icon'],
                            size: 32,
                            color: category['color'],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            category['title'],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 35),
              
              Text(
                'Your Music',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 15),
              
              // User Content Cards
              ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: userContent.length,
                itemBuilder: (context, index) {
                  var content = userContent[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: _buildGlassCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                content['image'],
                                height: 60,
                                width: 60,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    content['title'],
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    content['subtitle'],
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              content['icon'],
                              color: Colors.white70,
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}