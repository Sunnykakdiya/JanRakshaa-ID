import 'dart:convert';
import '../models/user_model.dart';

/// Handles encoding/decoding of QR code payloads.
/// The QR stores a compact JSON so emergency responders
/// can read it OFFLINE — no internet needed.
class QrService {
  static const String _appTag = 'JanRaksha';
  static const String _version = '2';

  // ── Encode user data → QR string ──────────────────────────
  static String generatePayload(UserModel user) {
    final payload = {
      'app': _appTag,
      'v': _version,
      'n': user.name,
      'bg': user.bloodGroup,
      'dob': user.dateOfBirth,
      'g': user.gender,
      'ph': user.phone,
      'al': user.allergies,
      'md': user.medications,
      'cn': user.conditions,
      'ec_n': user.emergencyContactName,
      'ec_p': user.emergencyContactPhone,
      'ec_r': user.emergencyContactRelation,
    };
    return jsonEncode(payload);
  }

  // ── Decode QR string → structured map ─────────────────────
  // Returns null if QR is not a valid JanRaksha code
  static Map<String, dynamic>? decodePayload(String raw) {
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      if (json['app'] != _appTag) return null;

      return {
        'name': json['n'] ?? '',
        'bloodGroup': json['bg'] ?? '',
        'dateOfBirth': json['dob'] ?? '',
        'gender': json['g'] ?? '',
        'phone': json['ph'] ?? '',
        'allergies': List<String>.from(json['al'] ?? []),
        'medications': List<String>.from(json['md'] ?? []),
        'conditions': List<String>.from(json['cn'] ?? []),
        'emergencyContactName': json['ec_n'] ?? '',
        'emergencyContactPhone': json['ec_p'] ?? '',
        'emergencyContactRelation': json['ec_r'] ?? '',
      };
    } catch (_) {
      return null; // not a JanRaksha QR
    }
  }
}