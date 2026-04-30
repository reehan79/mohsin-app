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
}
