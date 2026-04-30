class TaskItem {
  const TaskItem({
    required this.taskId,
    required this.type,
    required this.text,
    required this.language,
    required this.targetSound,
    required this.repetitions,
    required this.instruction,
  });

  final String taskId;
  final String type;
  final String text;
  final String language;
  final String targetSound;
  final int repetitions;
  final String instruction;

  factory TaskItem.fromMap(Map<String, dynamic> map) {
    return TaskItem(
      taskId: (map['task_id'] ?? map['taskId'] ?? '').toString(),
      type: (map['type'] ?? '').toString(),
      text: (map['text'] ?? '').toString(),
      language: (map['language'] ?? '').toString(),
      targetSound: (map['target_sound'] ?? map['targetSound'] ?? '').toString(),
      repetitions: (map['repetitions'] as num?)?.toInt() ?? 1,
      instruction: (map['instruction'] ?? '').toString(),
    );
  }
}
