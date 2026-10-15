import 'package:cloud_firestore/cloud_firestore.dart';

class VitalsEntry {
  final String id;
  final String userId;
  final int heartRate;        // bpm
  final int systolicBP;       // mmHg
  final int diastolicBP;      // mmHg
  final double weight;        // kg
  final double glucoseLevel;  // mmol/L
  final String notes;
  final DateTime timestamp;
  final String alertLevel;    // 'normal', 'warning', 'danger'

  const VitalsEntry({
    required this.id,
    required this.userId,
    required this.heartRate,
    required this.systolicBP,
    required this.diastolicBP,
    required this.weight,
    required this.glucoseLevel,
    this.notes = '',
    required this.timestamp,
    required this.alertLevel,
  });

  factory VitalsEntry.empty(String userId) => VitalsEntry(
    id: '',
    userId: userId,
    heartRate: 0,
    systolicBP: 0,
    diastolicBP: 0,
    weight: 0.0,
    glucoseLevel: 0.0,
    notes: '',
    timestamp: DateTime.now(),
    alertLevel: 'normal',
  );

  factory VitalsEntry.fromJson(Map<String, dynamic> json, String docId) {
    return VitalsEntry(
      id: docId,
      userId: json['userId'] ?? '',
      heartRate: (json['heartRate'] as num?)?.toInt() ?? 0,
      systolicBP: (json['systolicBP'] as num?)?.toInt() ?? 0,
      diastolicBP: (json['diastolicBP'] as num?)?.toInt() ?? 0,
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
      glucoseLevel: (json['glucoseLevel'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] ?? '',
      timestamp: json['timestamp'] is Timestamp
          ? (json['timestamp'] as Timestamp).toDate()
          : DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now(),
      alertLevel: json['alertLevel'] ?? 'normal',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'heartRate': heartRate,
      'systolicBP': systolicBP,
      'diastolicBP': diastolicBP,
      'weight': weight,
      'glucoseLevel': glucoseLevel,
      'notes': notes,
      'timestamp': Timestamp.fromDate(timestamp),
      'alertLevel': alertLevel,
    };
  }
}

class VitalsAlert {
  final bool hasAnomaly;
  final String anomalyDetected; // 'YES' or 'NO'
  final String trendSummary;
  final List<String> concerningFindings;
  final String recommendation;
  final String rawResponse;

  const VitalsAlert({
    required this.hasAnomaly,
    required this.anomalyDetected,
    required this.trendSummary,
    required this.concerningFindings,
    required this.recommendation,
    required this.rawResponse,
  });

  factory VitalsAlert.fromGeminiResponse(String response) {
    final bool hasAnomaly =
    response.toUpperCase().contains('ANOMALY_DETECTED: YES');

    String trendSummary = '';
    final trendMatch = RegExp(
      r'TREND_SUMMARY:\s*([\s\S]*?)(?=CONCERNING_FINDINGS:|$)',
      caseSensitive: false,
    ).firstMatch(response);
    if (trendMatch != null) {
      trendSummary = trendMatch.group(1)?.trim() ?? '';
    }

    List<String> findings = [];
    final findingsMatch = RegExp(
      r'CONCERNING_FINDINGS:\s*([\s\S]*?)(?=RECOMMENDATION:|$)',
      caseSensitive: false,
    ).firstMatch(response);
    if (findingsMatch != null) {
      final findingsText = findingsMatch.group(1)?.trim() ?? '';
      findings = findingsText
          .split('\n')
          .map((l) => l.replaceFirst(RegExp(r'^[•\-\*]\s*'), '').trim())
          .where((l) =>
      l.isNotEmpty && !l.toLowerCase().contains('none detected'))
          .toList();
    }

    String recommendation = '';
    final recMatch = RegExp(
      r'RECOMMENDATION:\s*([\s\S]*?)$',
      caseSensitive: false,
    ).firstMatch(response);
    if (recMatch != null) {
      recommendation = recMatch.group(1)?.trim() ?? '';
    }

    return VitalsAlert(
      hasAnomaly: hasAnomaly,
      anomalyDetected: hasAnomaly ? 'YES' : 'NO',
      trendSummary: trendSummary.isNotEmpty
          ? trendSummary
          : 'Vitals trend analyzed successfully.',
      concerningFindings: findings,
      recommendation: recommendation.isNotEmpty
          ? recommendation
          : 'Continue monitoring your vitals regularly.',
      rawResponse: response,
    );
  }
}