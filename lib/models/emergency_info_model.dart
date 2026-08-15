/// The result of decoding a JanRaksha emergency QR code.
/// This is intentionally separate from [UserModel] — a scanner should
/// never need (or be able to construct) a full account model, just the
/// handful of fields a first responder needs to see.
class EmergencyInfo {
  final String name;
  final String bloodGroup;
  final List<String> allergies;
  final List<String> medications;
  final List<String> conditions;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final String emergencyContactRelation;

  const EmergencyInfo({
    this.name = '',
    this.bloodGroup = '',
    this.allergies = const [],
    this.medications = const [],
    this.conditions = const [],
    this.emergencyContactName = '',
    this.emergencyContactPhone = '',
    this.emergencyContactRelation = '',
  });

  /// Parses the compact keys produced by [UserModel.toQrJson].
  factory EmergencyInfo.fromQrJson(Map<String, dynamic> json) {
    return EmergencyInfo(
      name: json['n'] ?? '',
      bloodGroup: json['bg'] ?? '',
      allergies: List<String>.from(json['al'] ?? const []),
      medications: List<String>.from(json['md'] ?? const []),
      conditions: List<String>.from(json['cn'] ?? const []),
      emergencyContactName: json['ec'] ?? '',
      emergencyContactPhone: json['ep'] ?? '',
      emergencyContactRelation: json['er'] ?? '',
    );
  }
}
