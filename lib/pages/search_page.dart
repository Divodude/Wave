import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:spotify_clone/pages/player.dart';
import "package:http/http.dart" as http;
import 'package:hive/hive.dart';
import 'package:spotify_clone/Hive_History.dart';
import 'package:shared_preferences/shared_preferences.dart';
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  String _currentQuery = '';
  bool _showRecentSearches = true;
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _debounceTimer;


  List<String> _recentSearches=['mood'];
    final box = Hive.box<SearchHistory>('SearchHistory');
void History() {

  setState(() {
    _recentSearches = box.values
        .map((item) => item.searchquery ?? '')
        .where((query) => query.isNotEmpty)
        .toList()
        .reversed
        .take(5)
        .toList();
  });
}
String baseUrl = "https://api-1039005314066.europe-west1.run.app/";




@override
  void initState(){
    History();
  }





  // Mock data - replace with your actual data source
 

  List<dynamic> _searchResults = [];
  
  final List<Map<String, dynamic>> _searchCategories = [
    {'icon': Icons.music_note, 'title': 'Podcasts'},
    {'icon': Icons.live_tv, 'title': 'Live Events'},
    {'icon': Icons.mood, 'title': 'Made For You'},
    {'icon': Icons.new_releases, 'title': 'New Releases'},
    {'icon': Icons.emoji_events, 'title': 'Charts'},
    {'icon': Icons.local_fire_department, 'title': 'Trending'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSearchData(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final encodedQuery = Uri.encodeComponent(query);
      final url ='$baseUrl/music/?title=$encodedQuery';
      
      final response = await http.get(
        Uri.parse(url),
        headers: await getAuthHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
         final decoded = jsonDecode(response.body);
  final List<dynamic> data = decoded['results']; // ✅ Correctly extract the list
        setState(() {
          _searchResults = data;
          _isLoading = false;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load search results (${response.statusCode})';
          _isLoading = false;
          _searchResults = [];
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error: ${e.toString()}';
        _isLoading = false;
        _searchResults = [];
      });
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

  void _onSearchChanged(String query) {
 
    // Cancel previous timer
    _debounceTimer?.cancel();
    
    setState(() {
      _currentQuery = query;
      _showRecentSearches = query.isEmpty;
    });

    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
        _errorMessage = null;
      });
      return;
    }

    // Debounce search to avoid too many API calls
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _loadSearchData(query);
    });
  }

  void _performSearch(String query) {
    box.add(SearchHistory(searchquery:query));
    if (query.isEmpty) return;
    
    _searchController.text = query;
    setState(() {
      _currentQuery = query;
      _showRecentSearches = false;
    });
    
    // Cancel debounce timer and search immediately
    _debounceTimer?.cancel();
    _loadSearchData(query);
  }

  void _clearSearch() {
    _searchController.clear();
    _debounceTimer?.cancel();
    setState(() {
      _currentQuery = '';
      _showRecentSearches = true;
      _searchResults = [];
      _isLoading = false;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Search"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFF121212),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'What do you want to listen to?',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                suffixIcon: _currentQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: _clearSearch,
                      )
                    : null,
              ),
              onChanged: _onSearchChanged,
              onSubmitted: _performSearch,
            ),
            
            const SizedBox(height: 24),
            
            // Content based on search state
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_showRecentSearches) {
      return _buildRecentSearchesAndCategories();
    } else if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.green,
        ),
      );
    } else if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadSearchData(_currentQuery),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    } else if (_searchResults.isEmpty && _currentQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off,
              color: Colors.grey,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'No results found for "$_currentQuery"',
              style: const TextStyle(color: Colors.grey, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    } else {
      return _buildSearchResults();
    }
  }

  Widget _buildRecentSearchesAndCategories() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent Searches section
          const Text(
            'Recent searches',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Recent searches chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _recentSearches.map((search) => GestureDetector(
              onTap: () => _performSearch(search),
              child: Chip(
                backgroundColor: Colors.grey[800],
                label: Text(
                  search,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            )).toList(),
          ),
          
          const SizedBox(height: 32),
          
          const Text(
            'Browse all',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Browse categories grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.5,
            ),
            itemCount: _searchCategories.length,
            itemBuilder: (context, index) {
              final category = _searchCategories[index];
              return Container(
                decoration: BoxDecoration(
                  color: _getCategoryColor(index),
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(category['icon'], color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        category['title'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'Songs (${_searchResults.length})',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: _searchResults.length,
            separatorBuilder: (context, index) => const Divider(
              color: Colors.grey,
              height: 1,
              indent: 60,
            ),
            itemBuilder: (context, index) {
              final song = _searchResults[index];
              return ListTile(
                leading: const Icon(Icons.music_note, color: Colors.white),
                title: Text(
                  song["name"] ?? 'Unknown Song',
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  song["artist"] ?? 'Unknown Artist',
                  style: const TextStyle(color: Colors.grey),
                ),
                onTap: () {
                  if (song["name"] != null && song["artist"] != null && song["song"] != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Player_Music(
                          coverImage: song["song_cover"] ?? '',

                          songName: song["name"],
                          artistName: song["artist"],
                          url: song["song"],
                          timestamp: 0.0,
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Song data is incomplete'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Color _getCategoryColor(int index) {
    final colors = [
      Colors.blue[800]!,
      Colors.purple[800]!,
      Colors.red[800]!,
      Colors.green[800]!,
      Colors.orange[800]!,
      Colors.pink[800]!,
    ];
    return colors[index % colors.length];
  }
}