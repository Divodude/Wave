import 'package:flutter/material.dart';
import 'package:spotify_clone/music.dart';
import 'package:spotify_clone/pages/home_page.dart';
import 'package:spotify_clone/pages/player.dart'; // adjust as needed
import 'package:spotify_clone/pages/search_page.dart';
import 'package:spotify_clone/pages/upload_page.dart';
import "room.dart"; // adjust as needed

class Main_Page extends StatefulWidget {
  const Main_Page({super.key});

  @override
  State<Main_Page> createState() => _Main_PageState();
}

class _Main_PageState extends State<Main_Page> {
  final audio = Music(); // Initialize your audio player

  int _currentIndex = 0;


  @override
  Widget build(BuildContext context) {
    
  // List of widgets for each bottom nav page
  final List<Widget> pages = [
    Home_Page(),
    Player_Music(url:audio.songUrl ,
    songName: audio.songName,
    coverImage: audio.coverImage,),
    Room_Sync(), // Adjust to your actual player widget
    
   

  ];
    return  Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      backgroundColor: Colors.transparent, // Spotify-like look
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 1,
        
        title: Row(
          children: [
            Text("Wave",style: TextStyle(fontSize: 30,fontWeight: FontWeight.bold,color: Colors.white),),
            Icon(Icons.graphic_eq, size: 30, color: Colors.white),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SearchPage()),
              );
            },
            icon: const Icon(Icons.search),
            iconSize: 30,
            color: Colors.white,
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UploadPage()),
              );
            },
            icon: const Icon(Icons.upload_file),
            iconSize: 30,
            color: Colors.white,
          ),
        ],
      ),


      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),

      bottomNavigationBar: BottomNavigationBar(
  backgroundColor: Colors.transparent, // Blends with body
  elevation: 4,
  selectedItemColor: const Color.fromARGB(255, 165, 165, 165),
  unselectedItemColor: const Color.fromARGB(255, 255, 254, 254),
  currentIndex: _currentIndex,
  onTap: (int index) {

    setState(() {
      _currentIndex = index;
    });
  },
  items: const [
    BottomNavigationBarItem(
      icon: Icon(Icons.home),
      label: 'Home',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.play_arrow),
      label: 'Player',
    ),
    BottomNavigationBarItem(icon: Icon(Icons.group),
    label: "SyncSonf]g")
    



    
  ],
      
        
      )
    );
  }
}
