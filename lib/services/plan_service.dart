import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../models/daily_plan.dart';

class PlanService {
  PlanService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  String todayDateString() => DateFormat('yyyy-MM-dd').format(DateTime.now());

  Future<DailyPlan?> loadTodayPlan() async {
    final String today = todayDateString();
    final DocumentSnapshot<Map<String, dynamic>> snapshot = await _firestore
        .collection('users')
        .doc('mohsin')
        .collection('plans')
        .doc(today)
        .get();

    if (!snapshot.exists) {
      return null;
    }

    final Map<String, dynamic>? data = snapshot.data();
    if (data == null) {
      return null;
    }

    return DailyPlan.fromMap(data);
  }

  /// Creates a default MVP test plan for today only if
  /// `users/mohsin/plans/YYYY-MM-DD` does not exist. Does not overwrite.
  Future<void> createDefaultPlanForTodayIfMissing() async {
    final String today = todayDateString();
    final DocumentReference<Map<String, dynamic>> ref = _firestore
        .collection('users')
        .doc('mohsin')
        .collection('plans')
        .doc(today);

    final DocumentSnapshot<Map<String, dynamic>> snapshot = await ref.get();
    if (snapshot.exists) {
      return;
    }

    await ref.set(_defaultTestPlanMap(today));
  }

  static Map<String, dynamic> _defaultTestPlanMap(String today) {
    return <String, dynamic>{
      'date': today,
      'user_id': 'mohsin',
      'plan_version': 'v0.1-auto',
      'schedule_type': 'test_day',
      'sessions': <Map<String, dynamic>>[
        <String, dynamic>{
          'session_id': 'evening',
          'title': 'Evening test practice',
          'preferred_time': '20:30',
          'follow_up_time': '21:00',
          'estimated_minutes': 10,
          'tasks': <Map<String, dynamic>>[
            <String, dynamic>{
              'task_id': 'word_school',
              'type': 'word',
              'text': 'school',
              'language': 'english',
              'target_sound': 'sk',
              'repetitions': 3,
              'instruction':
                  'Repeat slowly. Keep the first sound clear.',
            },
            <String, dynamic>{
              'task_id': 'word_red',
              'type': 'word',
              'text': 'red',
              'language': 'english',
              'target_sound': 'r',
              'repetitions': 3,
              'instruction': 'Repeat clearly. Do not rush.',
            },
            <String, dynamic>{
              'task_id': 'sentence_school',
              'type': 'sentence',
              'text': 'I go to school every day.',
              'language': 'english',
              'target_sound': 'sk',
              'repetitions': 2,
              'instruction': 'Read slowly and clearly.',
            },
          ],
        },
      ],
    };
  }
}
