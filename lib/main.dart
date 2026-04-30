import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MohsinSpeechPracticeApp());
}

class MohsinSpeechPracticeApp extends StatelessWidget {
  const MohsinSpeechPracticeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mohsin Speech Practice',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        scaffoldBackgroundColor: const Color(0xFFF6F7F9),
      ),
      home: const HomeScreen(),
    );
  }
}
