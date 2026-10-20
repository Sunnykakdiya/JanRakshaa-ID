class AppConstants {
  // App Info
  static const String appName = 'JanRaksha ID';
  static const String appVersion = '3.0.0';

  // Firestore Collections
  static const String usersCollection = 'users';
  static const String vitalsCollection = 'vitals';

  // ── Route Names ───────────────────────────────────────────────────────
  static const String loginRoute = '/login';
  static const String signupRoute = '/signup';
  static const String homeRoute = '/home';
  static const String profileRoute = '/profile';
  static const String editProfileRoute = '/edit-profile';
  static const String qrRoute = '/qr';
  static const String scanQrRoute = '/scan-qr';

  // Phase 3 — AI Routes
  static const String symptomCheckerRoute = '/symptom-checker';
  static const String drugCheckerRoute = '/drug-checker';
  static const String emergencyBriefRoute = '/emergency-brief';
  static const String geminiSettingsRoute = '/gemini-settings';

  // Phase 4–8 (placeholders)
  static const String docScannerRoute = '/doc-scanner';
  static const String vitalsRoute = '/vitals';
  static const String vitalsChartRoute = '/vitals-chart'; // ← Added here
  static const String sosRoute = '/sos';
  static const String faceLockRoute = '/face-lock';
  static const String hospitalFinderRoute = '/hospital-finder';

  // ── Blood Groups ──────────────────────────────────────────────────────
  static const List<String> bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-',
  ];

  // ── Gender ────────────────────────────────────────────────────────────
  static const List<String> genders = ['Male', 'Female', 'Other'];

  // ── Gemini AI Config ──────────────────────────────────────────────────
  // Get your free API key at: https://aistudio.google.com
  static const String geminiModel = 'gemini-3.1-flash-lite';
  static const String geminiApiKeyPref = 'gemini_api_key';
  static const String geminiStudioUrl = 'https://aistudio.google.com/app/apikey';
}