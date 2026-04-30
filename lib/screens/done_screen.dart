import 'package:flutter/material.dart';

class DoneScreen extends StatelessWidget {
  const DoneScreen({
    super.key,
    required this.totalAttempts,
    required this.uploadedCount,
    required this.pendingCount,
  });

  final int totalAttempts;
  final int uploadedCount;
  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Session complete')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Practice saved',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Text('Attempts recorded: $totalAttempts'),
              Text('Uploaded: $uploadedCount'),
              Text('Pending upload: $pendingCount'),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                  child: const Text('Back to home'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
