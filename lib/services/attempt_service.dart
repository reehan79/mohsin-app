import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../models/attempt.dart';

class AttemptService {
  AttemptService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _attemptsCollection => _firestore
      .collection('users')
      .doc('mohsin')
      .collection('attempts');

  Future<void> saveAttempt(Attempt attempt) {
    return _attemptsCollection.doc(attempt.attemptId).set(attempt.toMap());
  }

  Future<void> updateUploadStatus(
    String attemptId,
    String uploadStatus, {
    String? cloudAudioPath,
  }) {
    return _attemptsCollection.doc(attemptId).update(
      <String, dynamic>{
        'upload_status': uploadStatus,
        if (cloudAudioPath case final String path) 'cloud_audio_path': path,
      },
    );
  }

  Future<List<Attempt>> queryTodayAttempts() async {
    final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final QuerySnapshot<Map<String, dynamic>> snapshot = await _attemptsCollection
        .where('date', isEqualTo: today)
        .orderBy('created_at', descending: true)
        .get();

    return snapshot.docs
        .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
            Attempt.fromMap(doc.data()))
        .toList(growable: false);
  }
}
