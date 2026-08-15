import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/qr/my_qr_screen.dart';
import '../screens/qr/scan_qr_screen.dart';

// ── Phase 3: AI Screens ───────────────────────────────────────
import '../screens/ai/symptom_checker_screen.dart';
import '../screens/ai/drug_checker_screen.dart';

import 'constants.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
    // ── Auth ─────────────────────────────────────────────
      case AppConstants.loginRoute:
        return _slide(const LoginScreen());
      case AppConstants.signupRoute:
        return _slide(const SignupScreen());
      case AppConstants.homeRoute:
        return _slide(const HomeScreen());

    // ── Phase 2: Profile + QR ────────────────────────────
      case AppConstants.profileRoute:
        return _slide(const ProfileScreen());
      case AppConstants.editProfileRoute:
        return _slide(const EditProfileScreen());
      case AppConstants.qrRoute:
        return _slide(const MyQrScreen());
      case AppConstants.scanQrRoute:
        return _slide(const ScanQrScreen());

    // ── Phase 3: AI Features ─────────────────────────────
      case AppConstants.symptomCheckerRoute:
        return _slide(const SymptomCheckerScreen());
      case AppConstants.drugCheckerRoute:
        return _slide(const DrugCheckerScreen());

    // ── Placeholder routes for Phase 4–8 ─────────────────
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
          ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
          child: child,
        );
      },
    );
  }
}