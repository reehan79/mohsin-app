import 'session_plan.dart';

class DailyPlan {
  const DailyPlan({
    required this.date,
    required this.userId,
    required this.planVersion,
    required this.scheduleType,
    required this.sessions,
  });

  final String date;
  final String userId;
  final String planVersion;
  final String scheduleType;
  final List<SessionPlan> sessions;

  factory DailyPlan.fromMap(Map<String, dynamic> map) {
    final List<dynamic> rawSessions =
        (map['sessions'] as List<dynamic>?) ?? <dynamic>[];

    return DailyPlan(
      date: (map['date'] ?? '').toString(),
      userId: (map['user_id'] ?? map['userId'] ?? '').toString(),
      planVersion: (map['plan_version'] ?? map['planVersion'] ?? '').toString(),
      scheduleType: (map['schedule_type'] ?? map['scheduleType'] ?? '').toString(),
      sessions: rawSessions
          .whereType<Map<String, dynamic>>()
          .map(SessionPlan.fromMap)
          .toList(growable: false),
    );
  }
}
