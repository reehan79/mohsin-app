import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../models/attempt.dart';
import '../models/session_plan.dart';
import '../models/task_item.dart';
import '../services/attempt_service.dart';
import '../services/auth_service.dart';
import '../services/recording_service.dart';
import '../services/storage_service.dart';
import 'done_screen.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key, required this.session});

  final SessionPlan session;

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  final RecordingService _recordingService = RecordingService();
  final StorageService _storageService = StorageService();
  final AttemptService _attemptService = AttemptService();
  final AuthService _authService = AuthService();
  final Uuid _uuid = const Uuid();

  int _taskIndex = 0;
  int _repetition = 1;
  bool _isRecording = false;
  bool _isBusy = false;
  DateTime? _recordStartTime;
  int _totalAttempts = 0;
  int _uploadedCount = 0;
  int _pendingCount = 0;
  String? _currentRecordPath;

  TaskItem get _task => widget.session.tasks[_taskIndex];
  String get _dateString => DateFormat('yyyy-MM-dd').format(DateTime.now());
  int get _taskCount => widget.session.tasks.length;

  @override
  void dispose() {
    _recordingService.dispose();
    super.dispose();
  }

  Future<void> _onRecordPressed() async {
    if (_isBusy) {
      return;
    }

    if (_isRecording) {
      await _stopAndSave();
      return;
    }

    try {
      setState(() {
        _isBusy = true;
      });

      final String path = await _recordingService.startRecording(
        date: _dateString,
        sessionId: widget.session.sessionId,
        taskId: _task.taskId,
        repetitionNumber: _repetition,
      );

      setState(() {
        _currentRecordPath = path;
        _recordStartTime = DateTime.now();
        _isRecording = true;
      });
    } on RecordingPermissionException {
      _showMessage('Microphone permission denied.');
    } catch (_) {
      _showMessage('Recording failed to start.');
    } finally {
      setState(() {
        _isBusy = false;
      });
    }
  }

  Future<void> _stopAndSave() async {
    try {
      setState(() {
        _isBusy = true;
      });

      final String? localPath = await _recordingService.stopRecording();
      if (localPath == null || localPath.isEmpty) {
        _showMessage('Recording failed to save.');
        return;
      }

      final DateTime now = DateTime.now();
      final double? durationSeconds = _recordStartTime == null
          ? null
          : now.difference(_recordStartTime!).inMilliseconds / 1000.0;

      final StorageUploadResult? uploadResult =
          await _storageService.uploadAudioFile(
        localAudioPath: localPath,
        date: _dateString,
        sessionId: widget.session.sessionId,
        taskId: _task.taskId,
        repetitionNumber: _repetition,
      );

      final String attemptId = _uuid.v4();
      final Attempt attempt = Attempt(
        attemptId: attemptId,
        userId: _authService.currentUid ?? 'anonymous',
        date: _dateString,
        sessionId: widget.session.sessionId,
        taskId: _task.taskId,
        taskText: _task.text,
        repetitionNumber: _repetition,
        language: _task.language,
        targetSound: _task.targetSound,
        localAudioPath: localPath,
        cloudAudioPath: uploadResult?.downloadUrl ?? uploadResult?.cloudPath,
        durationSeconds: durationSeconds,
        uploadStatus: uploadResult == null ? 'pending' : 'uploaded',
        createdAt: now,
      );

      try {
        await _attemptService.saveAttempt(attempt);
      } catch (_) {
        _showMessage('Could not save attempt metadata.');
      }

      setState(() {
        _totalAttempts += 1;
        if (uploadResult == null) {
          _pendingCount += 1;
        } else {
          _uploadedCount += 1;
        }
      });

      _goToNextStep();
    } catch (_) {
      _showMessage('Recording stop failed.');
    } finally {
      setState(() {
        _isBusy = false;
        _isRecording = false;
        _recordStartTime = null;
        _currentRecordPath = null;
      });
    }
  }

  void _goToNextStep() {
    final bool lastRepetition = _repetition >= _task.repetitions;
    final bool lastTask = _taskIndex >= _taskCount - 1;

    if (lastRepetition && lastTask) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => DoneScreen(
            totalAttempts: _totalAttempts,
            uploadedCount: _uploadedCount,
            pendingCount: _pendingCount,
          ),
        ),
      );
      return;
    }

    setState(() {
      if (lastRepetition) {
        _taskIndex += 1;
        _repetition = 1;
      } else {
        _repetition += 1;
      }
    });
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.session.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Task ${_taskIndex + 1} of $_taskCount'),
            Text('Repetition $_repetition of ${_task.repetitions}'),
            const SizedBox(height: 16),
            Text(
              _task.text,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(_task.instruction),
            const SizedBox(height: 6),
            Text('Target sound: ${_task.targetSound}'),
            Text('Language: ${_task.language}'),
            const Spacer(),
            if (_isRecording && _currentRecordPath != null)
              Text(
                'Recording to: $_currentRecordPath',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isBusy ? null : _onRecordPressed,
                child: Text(_isRecording ? 'Stop recording' : 'Record repetition'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
