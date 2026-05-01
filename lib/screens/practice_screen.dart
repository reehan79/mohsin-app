import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../models/attempt.dart';
import '../models/session_plan.dart';
import '../models/task_item.dart';
import '../services/attempt_service.dart';
import '../services/auth_service.dart';
import '../services/background_upload_service.dart';
import '../services/recording_service.dart';
import '../services/reminder_service.dart';
import 'done_screen.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key, required this.session});

  final SessionPlan session;

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  final RecordingService _recordingService = RecordingService();
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
  String? _statusHint;

  TaskItem get _task => widget.session.tasks[_taskIndex];
  String get _dateString => DateFormat('yyyy-MM-dd').format(DateTime.now());
  int get _taskCount => widget.session.tasks.length;

  int get _totalRepetitionsInSession {
    int sum = 0;
    for (final TaskItem t in widget.session.tasks) {
      sum += t.repetitions;
    }
    return sum;
  }

  int get _completedRepetitionsBeforeCurrent {
    int sum = 0;
    for (int i = 0; i < _taskIndex; i++) {
      sum += widget.session.tasks[i].repetitions;
    }
    sum += _repetition - 1;
    return sum;
  }

  double get _sessionProgress {
    final int total = _totalRepetitionsInSession;
    if (total <= 0) {
      return 0;
    }
    return (_completedRepetitionsBeforeCurrent / total).clamp(0.0, 1.0);
  }

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
        _statusHint = null;
      });

      await _recordingService.startRecording(
        date: _dateString,
        sessionId: widget.session.sessionId,
        taskId: _task.taskId,
        repetitionNumber: _repetition,
      );

      setState(() {
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
        cloudAudioPath: null,
        durationSeconds: durationSeconds,
        uploadStatus: 'pending',
        createdAt: now,
      );

      try {
        await _attemptService.saveAttempt(attempt);
      } catch (_) {
        _showMessage('Could not save attempt metadata.');
        return;
      }

      setState(() {
        _totalAttempts += 1;
        _pendingCount += 1;
        _statusHint =
            'Recording saved\nUploading in background';
      });

      BackgroundUploadService.instance.enqueue(
        BackgroundUploadJob(
          attemptId: attemptId,
          localAudioPath: localPath,
          date: _dateString,
          sessionId: widget.session.sessionId,
          taskId: _task.taskId,
          repetitionNumber: _repetition,
          onSuccess: () {
            if (!mounted) {
              return;
            }
            setState(() {
              _pendingCount -= 1;
              _uploadedCount += 1;
            });
          },
        ),
      );

      await _goToNextStep();
    } catch (_) {
      _showMessage('Recording stop failed.');
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
          _isRecording = false;
          _recordStartTime = null;
        });
      }
    }
  }

  Future<void> _goToNextStep() async {
    final bool lastRepetition = _repetition >= _task.repetitions;
    final bool lastTask = _taskIndex >= _taskCount - 1;

    if (lastRepetition && lastTask) {
      await ReminderService.instance
          .cancelSessionFollowUp(widget.session.sessionId);
      if (!mounted) {
        return;
      }
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
      _statusHint = null;
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
    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.session.title),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Task ${_taskIndex + 1} of $_taskCount',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Repetition $_repetition of ${_task.repetitions}',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: _sessionProgress,
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.35),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            _task.text,
                            style: textTheme.headlineSmall?.copyWith(
                              height: 1.25,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _task.instruction,
                            style: textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Target sound: ${_task.targetSound}',
                            style: textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Language: ${_task.language}',
                            style: textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (_isRecording)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Recording...',
                        style: textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              if (_statusHint != null && !_isRecording)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _statusHint!,
                    style: textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _isBusy ? null : _onRecordPressed,
                  style: FilledButton.styleFrom(
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: Text(
                    _isRecording ? 'Stop Recording' : 'Start Recording',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
