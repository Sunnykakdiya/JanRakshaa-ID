import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vitals_model.dart';

class VitalsThreshold {
  static const int heartRateMin = 40;
  static const int heartRateMax = 150;
  static const int heartRateWarningMin = 55;
  static const int heartRateWarningMax = 100;

  static const double glucoseMin = 3.5;
  static const double glucoseMax = 16.7;
  static const double glucoseWarningMin = 4.0;
  static const double glucoseWarningMax = 10.0;

  static const int systolicMin = 80;
  static const int systolicMax = 180;
  static const int systolicWarningMin = 90;
  static const int systolicWarningMax = 140;

  static String classify({
    required int heartRate,
    required int systolicBP,
    required double glucoseLevel,
  }) {
    if (heartRate < heartRateMin ||
        heartRate > heartRateMax ||
        glucoseLevel < glucoseMin ||
        glucoseLevel > glucoseMax ||
        systolicBP < systolicMin ||
        systolicBP > systolicMax) {
      return 'danger';
    }
    if (heartRate < heartRateWarningMin ||
        heartRate > heartRateWarningMax ||
        glucoseLevel < glucoseWarningMin ||
        glucoseLevel > glucoseWarningMax ||
        systolicBP < systolicWarningMin ||
        systolicBP > systolicWarningMax) {
      return 'warning';
    }
    return 'normal';
  }
}

class VitalsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _vitalsRef(String uid) {
    return _firestore.collection('users').doc(uid).collection('vitals');
  }

  Future<void> saveVitals(VitalsEntry entry) async {
    await _vitalsRef(entry.userId).add(entry.toJson());
  }

  Stream<List<VitalsEntry>> getVitalsStream(String uid) {
    return _vitalsRef(uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => VitalsEntry.fromJson(doc.data(), doc.id))
        .toList());
  }

  Future<List<VitalsEntry>> getRecentVitals(String uid, {int limit = 14}) async {
    final snapshot = await _vitalsRef(uid)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs
        .map((doc) => VitalsEntry.fromJson(doc.data(), doc.id))
        .toList();
  }

  Future<void> deleteVitals(String uid, String entryId) async {
    await _vitalsRef(uid).doc(entryId).delete();
  }
}