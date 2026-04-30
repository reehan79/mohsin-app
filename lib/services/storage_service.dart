import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

class StorageUploadResult {
  const StorageUploadResult({
    required this.cloudPath,
    required this.downloadUrl,
  });

  final String cloudPath;
  final String? downloadUrl;
}

class StorageService {
  StorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  Future<StorageUploadResult?> uploadAudioFile({
    required String localAudioPath,
    required String date,
    required String sessionId,
    required String taskId,
    required int repetitionNumber,
  }) async {
    final String paddedRep = repetitionNumber.toString().padLeft(2, '0');
    final String cloudPath =
        'audio/mohsin/$date/$sessionId/${taskId}_rep_$paddedRep.m4a';

    try {
      final Reference reference = _storage.ref().child(cloudPath);
      await reference.putFile(File(localAudioPath));

      String? downloadUrl;
      try {
        downloadUrl = await reference.getDownloadURL();
      } catch (_) {
        downloadUrl = null;
      }

      return StorageUploadResult(
        cloudPath: cloudPath,
        downloadUrl: downloadUrl,
      );
    } catch (_) {
      return null;
    }
  }
}
