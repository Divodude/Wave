  import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:spotify_clone/authservice.dart';

import 'firebase_options.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'Hive_History.dart';

import 'package:spotify_clone/pages/login.dart';
import 'package:spotify_clone/pages/main_page.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(HiveHistoryAdapter());
  await Hive.openBox<HiveHistory>('historyBox');
  await Hive.openBox<SearchHistory>('SearchHistory'); 
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyAPP());
}

class MyAPP extends StatelessWidget {
  const MyAPP({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Spotify Clone',
      home: FutureBuilder<bool>(
        future: AuthService().isLoggedIn(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return snapshot.data! ? const Main_Page() : const Login_Page();
        },
      ),
    );
  }
}
