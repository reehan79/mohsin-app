import 'package:flutter/material.dart';

import '../models/session_plan.dart';

class SessionCard extends StatelessWidget {
  const SessionCard({
    super.key,
    required this.session,
    required this.onStart,
  });

  final SessionPlan session;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              session.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text('Preferred time: ${session.preferredTime}'),
            Text('Tasks: ${session.tasks.length}'),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: onStart,
                child: const Text('Start'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
