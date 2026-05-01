import 'dart:io';

import '../models/attempt.dart';
import 'attempt_service.dart';
import 'background_upload_service.dart';

class UploadRetryService {
  UploadRetryService({
    AttemptService? attemptService,
    BackgroundUploadService? backgroundUpload,
  })  : _attempts = attemptService ?? AttemptService(),
        _background = backgroundUpload ?? BackgroundUploadService.instance;

  final AttemptService _attempts;
  final BackgroundUploadService _background;

  /// Enqueues background uploads for pending attempts whose local file still exists.
  Future<void> retryPendingUploads() async {
    final List<Attempt> pending = await _attempts.queryPendingAttempts();
    for (final Attempt attempt in pending) {
      if (!File(attempt.localAudioPath).existsSync()) {
        continue;
      }
      _background.enqueue(
        BackgroundUploadJob(
          attemptId: attempt.attemptId,
          localAudioPath: attempt.localAudioPath,
          date: attempt.date,
          sessionId: attempt.sessionId,
          taskId: attempt.taskId,
          repetitionNumber: attempt.repetitionNumber,
        ),
      );
    }
  }
}
