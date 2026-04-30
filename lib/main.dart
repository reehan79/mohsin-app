import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  final UserCredential userCredential =
      await FirebaseAuth.instance.signInAnonymously();

  runApp(
    MohsinSpeechPracticeApp(
      anonymousUid: userCredential.user?.uid,
    ),
  );
}

class MohsinSpeechPracticeApp extends StatelessWidget {
  const MohsinSpeechPracticeApp({super.key, required this.anonymousUid});

  final String? anonymousUid;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mohsin Speech Practice',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: FirebaseStatusScreen(anonymousUid: anonymousUid),
    );
  }
}

class FirebaseStatusScreen extends StatelessWidget {
  const FirebaseStatusScreen({super.key, required this.anonymousUid});

  final String? anonymousUid;

  @override
  Widget build(BuildContext context) {
    final String uidText = anonymousUid ?? 'Unavailable';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mohsin Speech Practice'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Firebase status: Connected',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Text(
                'Anonymous UID: $uidText',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 12),
              const Text(
                'Speech MVP setup ready',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
