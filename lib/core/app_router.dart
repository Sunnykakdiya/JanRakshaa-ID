import 'package:flutter/material.dart';

// Auth
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';

// Core
import '../screens/home/home_screen.dart';

// Profile
import '../screens/profile/profile_screen.dart';
import '../screens/profile/edit_profile_screen.dart';

// QR
import '../screens/qr/my_qr_screen.dart';
import '../screens/qr/scan_qr_screen.dart';

// Phase 3 — AI
import '../screens/ai/symptom_checker_screen.dart';
import '../screens/ai/drug_checker_screen.dart';
import '../screens/ai/gemini_key_screen.dart';

// Phase 4 — OCR
import '../screens/ai/doc_scanner_screen.dart';

import 'constants.dart';

// Phase 5 - vital
import '../screens/vitals/vitals_tracker_screen.dart';
import '../screens/vitals/vitals_chart_screen.dart';

// Phase 6 - SOS
import '../screens/sos/voice_sos_screen.dart';

//Phase 7 - biomatric
import '../screens/biometric/face_lock_screen.dart';

// Phase 8 - hospital
import '../screens/hospital/hospital_finder_screen.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
    // ── Auth ────────────────────────────────────────────────────
      case AppConstants.loginRoute:
        return _slide(const LoginScreen());
      case AppConstants.signupRoute:
        return _slide(const SignupScreen());

    // ── Core ────────────────────────────────────────────────────
      case AppConstants.homeRoute:
        return _slide(const HomeScreen());

    // ── Profile ─────────────────────────────────────────────────
      case AppConstants.profileRoute:
        return _slide(const ProfileScreen());
      case AppConstants.editProfileRoute:
        return _slide(const EditProfileScreen());

    // ── QR Code ─────────────────────────────────────────────────
      case AppConstants.qrRoute:
        return _slide(const MyQrScreen());
      case AppConstants.scanQrRoute:
        return _slide(const ScanQrScreen());

    // ── Phase 3: Gemini AI ───────────────────────────────────────
      case AppConstants.symptomCheckerRoute:
        return _slide(const SymptomCheckerScreen());
      case AppConstants.drugCheckerRoute:
        return _slide(const DrugCheckerScreen());
      case AppConstants.geminiSettingsRoute:
        return _slide(const GeminiKeyScreen());

    // ── Phase 4: OCR Scanner ─────────────────────────────────────
      case AppConstants.docScannerRoute:
        return _slide(const DocScannerScreen());

        // ── Phase 5: Vital ───────────────────────────────────────
      case AppConstants.vitalsRoute:
        return MaterialPageRoute(builder: (_) => const VitalsTrackerScreen());
      case AppConstants.vitalsChartRoute:
        return MaterialPageRoute(builder: (_) => const VitalsChartScreen());

        // ── Phase 6: SOS ───────────────────────────────────────
      case AppConstants.sosRoute:
        return MaterialPageRoute(builder: (_) => const VoiceSosScreen());

        // ── Phase 7: Biometric ───────────────────────────────────
      case AppConstants.faceLockRoute:
        final redirectRoute = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => FaceLockScreen(redirectRoute: redirectRoute),
        );

        // ── Phase 8: Hospital ───────────────────────────────────
      case AppConstants.hospitalFinderRoute:
        return MaterialPageRoute(builder: (_) => const HospitalFinderScreen());


    // ── Fallback ────────────────────────────────────────────────
      default:
        return _slide(const HomeScreen());


    }
  }

  static PageRouteBuilder _slide(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          )),
          child: child,
        );
      },
    );
  }
}
