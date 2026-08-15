class AppConstants {
  // App Info
  static const String appName = 'JanRaksha ID';
  static const String appVersion = '2.0.0';

  // Firestore Collections
  static const String usersCollection = 'users';
  static const String vitalsCollection = 'vitals';

  // Route Names
  static const String loginRoute = '/login';
  static const String signupRoute = '/signup';
  static const String homeRoute = '/home';
  static const String profileRoute = '/profile';
  static const String editProfileRoute = '/edit-profile';
  static const String qrRoute = '/qr';
  static const String scanQrRoute = '/scan-qr';
  static const String symptomCheckerRoute = '/symptom-checker';
  static const String drugCheckerRoute = '/drug-checker';
  static const String docScannerRoute = '/doc-scanner';
  static const String vitalsRoute = '/vitals';
  static const String sosRoute = '/sos';

  // Blood Groups (for dropdown)
  static const List<String> bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-',
  ];

  // Gender options
  static const List<String> genders = ['Male', 'Female', 'Other'];
}
