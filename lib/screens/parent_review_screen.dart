import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/attempt.dart';
import '../services/attempt_service.dart';

class ParentReviewScreen extends StatefulWidget {
  const ParentReviewScreen({super.key});

  @override
  State<ParentReviewScreen> createState() => _ParentReviewScreenState();
}

class _ParentReviewScreenState extends State<ParentReviewScreen> {
  final AttemptService _attemptService = AttemptService();
  late Future<List<Attempt>> _attemptsFuture;

  @override
  void initState() {
    super.initState();
    _attemptsFuture = _attemptService.queryTodayAttempts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Parent review')),
      body: FutureBuilder<List<Attempt>>(
        future: _attemptsFuture,
        builder:
            (BuildContext context, AsyncSnapshot<List<Attempt>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Could not load attempts.'));
          }

          final List<Attempt> attempts = snapshot.data ?? <Attempt>[];
          if (attempts.isEmpty) {
            return const Center(child: Text('No attempts recorded today.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: attempts.length,
            separatorBuilder: (_, index) => const SizedBox(height: 10),
            itemBuilder: (BuildContext context, int index) {
              final Attempt attempt = attempts[index];
              final String createdAtText =
                  DateFormat('yyyy-MM-dd HH:mm').format(attempt.createdAt);
              return Card(
                child: ListTile(
                  title: Text(attempt.taskText),
                  subtitle: Text(
                    'Repetition ${attempt.repetitionNumber} • ${attempt.uploadStatus}\n$createdAtText',
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
