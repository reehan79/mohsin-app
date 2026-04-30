class Attempt {
  const Attempt({
    required this.attemptId,
    required this.userId,
    required this.date,
    required this.sessionId,
    required this.taskId,
    required this.taskText,
    required this.repetitionNumber,
    required this.language,
    required this.targetSound,
    required this.localAudioPath,
    required this.cloudAudioPath,
    required this.durationSeconds,
    required this.uploadStatus,
    required this.createdAt,
  });

  final String attemptId;
  final String userId;
  final String date;
  final String sessionId;
  final String taskId;
  final String taskText;
  final int repetitionNumber;
  final String language;
  final String targetSound;
  final String localAudioPath;
  final String? cloudAudioPath;
  final double? durationSeconds;
  final String uploadStatus;
  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'attempt_id': attemptId,
      'user_id': userId,
      'date': date,
      'session_id': sessionId,
      'task_id': taskId,
      'task_text': taskText,
      'repetition_number': repetitionNumber,
      'language': language,
      'target_sound': targetSound,
      'local_audio_path': localAudioPath,
      'cloud_audio_path': cloudAudioPath,
      'duration_seconds': durationSeconds,
      'upload_status': uploadStatus,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Attempt.fromMap(Map<String, dynamic> map) {
    return Attempt(
      attemptId: (map['attempt_id'] ?? map['attemptId'] ?? '').toString(),
      userId: (map['user_id'] ?? map['userId'] ?? '').toString(),
      date: (map['date'] ?? '').toString(),
      sessionId: (map['session_id'] ?? map['sessionId'] ?? '').toString(),
      taskId: (map['task_id'] ?? map['taskId'] ?? '').toString(),
      taskText: (map['task_text'] ?? map['taskText'] ?? '').toString(),
      repetitionNumber: (map['repetition_number'] as num?)?.toInt() ??
          (map['repetitionNumber'] as num?)?.toInt() ??
          1,
      language: (map['language'] ?? '').toString(),
      targetSound: (map['target_sound'] ?? map['targetSound'] ?? '').toString(),
      localAudioPath: (map['local_audio_path'] ?? map['localAudioPath'] ?? '')
          .toString(),
      cloudAudioPath: map['cloud_audio_path']?.toString() ?? map['cloudAudioPath']?.toString(),
      durationSeconds: (map['duration_seconds'] as num?)?.toDouble() ??
          (map['durationSeconds'] as num?)?.toDouble(),
      uploadStatus: (map['upload_status'] ?? map['uploadStatus'] ?? '').toString(),
      createdAt: DateTime.tryParse((map['created_at'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}
