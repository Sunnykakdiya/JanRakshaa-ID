// ── BUG FIX (Phase 3) ────────────────────────────────────────
// Fixed toQrJson() key names to match EmergencyInfo.fromQrJson():
//   ec_n → ec   (emergencyContactName)
//   ec_p → ep   (emergencyContactPhone)
//   ec_r → er   (emergencyContactRelation)
// ─────────────────────────────────────────────────────────────

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String bloodGroup;
  final String dateOfBirth;
  final String gender;
  final List<String> allergies;
  final List<String> medications;
  final List<String> conditions;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final String emergencyContactRelation;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.phone = '',
    this.bloodGroup = '',
    this.dateOfBirth = '',
    this.gender = '',
    this.allergies = const [],
    this.medications = const [],
    this.conditions = const [],
    this.emergencyContactName = '',
    this.emergencyContactPhone = '',
    this.emergencyContactRelation = '',
    this.profileImageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      bloodGroup: json['bloodGroup'] ?? '',
      dateOfBirth: json['dateOfBirth'] ?? '',
      gender: json['gender'] ?? '',
      allergies: List<String>.from(json['allergies'] ?? []),
      medications: List<String>.from(json['medications'] ?? []),
      conditions: List<String>.from(json['conditions'] ?? []),
      emergencyContactName: json['emergencyContactName'] ?? '',
      emergencyContactPhone: json['emergencyContactPhone'] ?? '',
      emergencyContactRelation: json['emergencyContactRelation'] ?? '',
      profileImageUrl: json['profileImageUrl'],
      createdAt: DateTime.parse(
          json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(
          json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'bloodGroup': bloodGroup,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'allergies': allergies,
      'medications': medications,
      'conditions': conditions,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
      'emergencyContactRelation': emergencyContactRelation,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Compact payload for QR code — keys MUST match EmergencyInfo.fromQrJson()
  Map<String, dynamic> toQrJson() {
    return {
      'n': name,
      'bg': bloodGroup,
      'dob': dateOfBirth,
      'g': gender,
      'ph': phone,
      'al': allergies,
      'md': medications,
      'cn': conditions,
      'ec': emergencyContactName,   // ← FIXED: was 'ec_n'
      'ep': emergencyContactPhone,  // ← FIXED: was 'ec_p'
      'er': emergencyContactRelation, // ← FIXED: was 'ec_r'
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? bloodGroup,
    String? dateOfBirth,
    String? gender,
    List<String>? allergies,
    List<String>? medications,
    List<String>? conditions,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? emergencyContactRelation,
    String? profileImageUrl,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      allergies: allergies ?? this.allergies,
      medications: medications ?? this.medications,
      conditions: conditions ?? this.conditions,
      emergencyContactName:
      emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone:
      emergencyContactPhone ?? this.emergencyContactPhone,
      emergencyContactRelation:
      emergencyContactRelation ?? this.emergencyContactRelation,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}