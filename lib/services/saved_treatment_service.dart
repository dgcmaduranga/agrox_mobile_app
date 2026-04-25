import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SavedTreatmentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // =========================
  // SAVE TREATMENT
  // =========================
  static Future<void> saveTreatment({
    required String diseaseName,
    required String crop,
    required String riskLevel,
    required String description,
    required List<String> treatments,
    required double accuracy,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      return;
    }

    final savedRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('saved_treatments');

    await savedRef.add({
      'diseaseName': diseaseName,
      'crop': crop,
      'riskLevel': riskLevel,
      'description': description,
      'treatments': treatments,
      'accuracy': accuracy,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // =========================
  // GET SAVED TREATMENTS
  // =========================
  static Stream<List<Map<String, dynamic>>> getSavedTreatments() {
    final user = _auth.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('saved_treatments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();

        return {
          'id': doc.id,
          'diseaseName': data['diseaseName'] ?? 'Unknown Disease',
          'crop': data['crop'] ?? 'Unknown Crop',
          'riskLevel': data['riskLevel'] ?? 'Low',
          'description': data['description'] ?? 'No description available.',
          'treatments': data['treatments'] ?? [],
          'accuracy': data['accuracy'] ?? 0.0,
          'createdAt': data['createdAt'],
        };
      }).toList();
    });
  }

  // =========================
  // DELETE ONE SAVED TREATMENT
  // =========================
  static Future<void> deleteSavedTreatment(String id) async {
    final user = _auth.currentUser;

    if (user == null) {
      return;
    }

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('saved_treatments')
        .doc(id)
        .delete();
  }

  // =========================
  // CLEAR ALL SAVED TREATMENTS
  // =========================
  static Future<void> clearSavedTreatments() async {
    final user = _auth.currentUser;

    if (user == null) {
      return;
    }

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('saved_treatments')
        .get();

    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}