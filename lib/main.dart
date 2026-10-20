import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'providers/vitals_provider.dart';

import 'firebase_options.dart';
import 'core/theme.dart';
import 'core/app_router.dart';
import 'providers/auth_provider.dart';
import 'providers/user_provider.dart';        // ← Phase 3 addition
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'providers/sos_provider.dart'; // ← Phase 6 addition
import 'providers/face_lock_provider.dart';
import 'providers/hospital_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const JanRakshaApp());
}

class JanRakshaApp extends StatelessWidget {
  const JanRakshaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // ── Phase 3: UserProvider added ──────────────────────────────
        // Required by SymptomCheckerScreen, DrugCheckerScreen,
        // DocScannerScreen, ScanExtractResultScreen, and HomeScreen.
        // Listens to Firebase auth directly — no manual wiring needed.
        ChangeNotifierProvider(create: (_) => UserProvider()),
        // Phase 5 will add: ChangeNotifierProvider(create: (_) => VitalsProvider()),
        ChangeNotifierProvider(create: (_) => VitalsProvider()),
        ChangeNotifierProvider(create: (_) => SosProvider()),
        ChangeNotifierProvider(create: (_) => FaceLockProvider()),
        ChangeNotifierProvider(create: (_) => HospitalProvider()),
      ],
      child: MaterialApp(
        title: 'JanRaksha ID',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        onGenerateRoute: AppRouter.generateRoute,
        home: const AuthWrapper(),
      ),
    );
  }
}

/// Watches AuthProvider and routes to the correct screen automatically.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    switch (authProvider.status) {
      case AuthStatus.loading:
        return const _SplashScreen();
      case AuthStatus.authenticated:
        return const HomeScreen();
      case AuthStatus.unauthenticated:
        return const LoginScreen();
    }
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.medical_services, color: Colors.white, size: 64),
            SizedBox(height: 16),
            Text(
              'JanRaksha ID',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(
                color: Colors.white54, strokeWidth: 2),
          ],
        ),
      ),
    );
  }
}
