import 'dart:collection';

import 'package:flutter/material.dart';

import '../scaffold_messenger_key.dart';
import 'attempt_service.dart';
import 'storage_service.dart';

class BackgroundUploadJob {
  const BackgroundUploadJob({
    required this.attemptId,
    required this.localAudioPath,
    required this.date,
    required this.sessionId,
    required this.taskId,
    required this.repetitionNumber,
    this.onSuccess,
  });

  final String attemptId;
  final String localAudioPath;
  final String date;
  final String sessionId;
  final String taskId;
  final int repetitionNumber;
  final void Function()? onSuccess;
}

class BackgroundUploadService {
  BackgroundUploadService._();

  static final BackgroundUploadService instance = BackgroundUploadService._();

  final Queue<BackgroundUploadJob> _queue = Queue<BackgroundUploadJob>();
  final Set<String> _queuedOrProcessing = <String>{};
  bool _processing = false;

  final StorageService _storage = StorageService();
  final AttemptService _attempts = AttemptService();

  void enqueue(BackgroundUploadJob job) {
    if (_queuedOrProcessing.contains(job.attemptId)) {
      return;
    }
    _queuedOrProcessing.add(job.attemptId);
    _queue.add(job);
    _pump();
  }

  Future<void> _pump() async {
    if (_processing) {
      return;
    }
    _processing = true;
    try {
      while (_queue.isNotEmpty) {
        final BackgroundUploadJob job = _queue.removeFirst();
        try {
          final StorageUploadResult? result = await _storage.uploadAudioFile(
            localAudioPath: job.localAudioPath,
            date: job.date,
            sessionId: job.sessionId,
            taskId: job.taskId,
            repetitionNumber: job.repetitionNumber,
          );
          if (result != null) {
            final String path = result.downloadUrl ?? result.cloudPath;
            await _attempts.updateUploadStatus(
              job.attemptId,
              'uploaded',
              cloudAudioPath: path,
            );
            job.onSuccess?.call();
          } else {
            _showFailureSnack();
          }
        } catch (_) {
          _showFailureSnack();
        } finally {
          _queuedOrProcessing.remove(job.attemptId);
        }
      }
    } finally {
      _processing = false;
    }
  }

  void _showFailureSnack() {
    rootScaffoldMessengerKey.currentState?.showSnackBar(
      const SnackBar(
        content: Text('Saved locally. Upload will be retried later.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
