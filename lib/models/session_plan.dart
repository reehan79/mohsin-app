import 'task_item.dart';

class SessionPlan {
  const SessionPlan({
    required this.sessionId,
    required this.title,
    required this.preferredTime,
    required this.followUpTime,
    required this.estimatedMinutes,
    required this.tasks,
  });

  final String sessionId;
  final String title;
  final String preferredTime;
  final String followUpTime;
  final int estimatedMinutes;
  final List<TaskItem> tasks;

  factory SessionPlan.fromMap(Map<String, dynamic> map) {
    final List<dynamic> rawTasks = (map['tasks'] as List<dynamic>?) ?? <dynamic>[];

    return SessionPlan(
      sessionId: (map['session_id'] ?? map['sessionId'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      preferredTime: (map['preferred_time'] ?? map['preferredTime'] ?? '').toString(),
      followUpTime: (map['follow_up_time'] ?? map['followUpTime'] ?? '').toString(),
      estimatedMinutes: (map['estimated_minutes'] as num?)?.toInt() ??
          (map['estimatedMinutes'] as num?)?.toInt() ??
          0,
      tasks: rawTasks
          .whereType<Map<String, dynamic>>()
          .map(TaskItem.fromMap)
          .toList(growable: false),
    );
  }
}
