import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'screens/login_screen.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Firebase'i başlat
  runApp(const StudyTrackApp());
}

class StudyTrackApp extends StatelessWidget {
  const StudyTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StudyTrack',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      home: const LoginScreen(), 
    );
  }
}