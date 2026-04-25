import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistoryService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // =========================
  // SAVE DETECTION HISTORY
  // =========================
  static Future<void> saveDetection({
    required String diseaseName,
    required String crop,
    required String riskLevel,
    required double accuracy,
    required DateTime dateTime,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      return;
    }

    final historyRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('detection_history');

    await historyRef.add({
      'diseaseName': diseaseName,
      'crop': crop,
      'riskLevel': riskLevel,
      'accuracy': accuracy,
      'dateTime': Timestamp.fromDate(dateTime),
      'createdAt': FieldValue.serverTimestamp(),
      'userId': user.uid,
    });

    await _keepOnlyLastFive(user.uid);
  }

  // =========================
  // GET LAST 5 DETECTIONS
  // =========================
  static Stream<List<Map<String, dynamic>>> getRecentDetections() {
    final user = _auth.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('detection_history')
        .orderBy('dateTime', descending: true)
        .limit(5)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();

        final double accuracy = data['accuracy'] is num
            ? (data['accuracy'] as num).toDouble()
            : double.tryParse(data['accuracy']?.toString() ?? '0') ?? 0.0;

        return {
          'id': doc.id,
          'diseaseName': data['diseaseName'] ?? 'Unknown Disease',
          'crop': data['crop'] ?? 'Unknown Crop',
          'riskLevel': data['riskLevel'] ?? 'Low',
          'accuracy': accuracy,
          'dateTime': data['dateTime'],
          'createdAt': data['createdAt'],
          'userId': data['userId'],
        };
      }).toList();
    });
  }

  // =========================
  // DELETE ONE HISTORY ITEM
  // =========================
  static Future<void> deleteDetection(String id) async {
    final user = _auth.currentUser;

    if (user == null) {
      return;
    }

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('detection_history')
        .doc(id)
        .delete();
  }

  // =========================
  // CLEAR ALL HISTORY
  // =========================
  static Future<void> clearHistory() async {
    final user = _auth.currentUser;

    if (user == null) {
      return;
    }

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('detection_history')
        .get();

    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  // =========================
  // KEEP ONLY LAST 5
  // =========================
  static Future<void> _keepOnlyLastFive(String uid) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('detection_history')
        .orderBy('dateTime', descending: true)
        .get();

    if (snapshot.docs.length <= 5) {
      return;
    }

    final oldDocs = snapshot.docs.skip(5).toList();
    final batch = _firestore.batch();

    for (final doc in oldDocs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}