import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class RecordingService {
  final AudioRecorder _recorder = AudioRecorder();
  String? _currentPath;

  Future<bool> hasPermission() {
    return _recorder.hasPermission();
  }

  Future<String> startRecording({
    required String date,
    required String sessionId,
    required String taskId,
    required int repetitionNumber,
  }) async {
    final bool permission = await hasPermission();
    if (!permission) {
      throw RecordingPermissionException();
    }

    final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
    final Directory audioDir =
        Directory('${appDocumentsDir.path}/audio/$date/$sessionId');
    if (!audioDir.existsSync()) {
      await audioDir.create(recursive: true);
    }

    final String paddedRep = repetitionNumber.toString().padLeft(2, '0');
    final String path = '${audioDir.path}/${taskId}_rep_$paddedRep.m4a';

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000),
      path: path,
    );

    _currentPath = path;
    return path;
  }

  Future<String?> stopRecording() async {
    final String? stoppedPath = await _recorder.stop();
    return stoppedPath ?? _currentPath;
  }

  Future<void> dispose() {
    return _recorder.dispose();
  }
}

class RecordingPermissionException implements Exception {}
