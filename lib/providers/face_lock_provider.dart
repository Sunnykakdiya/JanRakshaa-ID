import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/face_lock_service.dart';

class FaceLockProvider extends ChangeNotifier {
  static const String _prefKey = 'face_biometric_lock_enabled';

  bool _isLockEnabled = false;
  bool _isSessionUnlocked = false;
  bool _isProcessing = false;
  BiometricAuthResult? _lastResult;
  List<BiometricType> _enrolledTypes = [];

  bool get isLockEnabled => _isLockEnabled;
  bool get isSessionUnlocked => _isSessionUnlocked;
  bool get isProcessing => _isProcessing;
  BiometricAuthResult? get lastResult => _lastResult;
  List<BiometricType> get enrolledTypes => _enrolledTypes;

  FaceLockProvider() {
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    _isLockEnabled = prefs.getBool(_prefKey) ?? false;
    _enrolledTypes = await FaceLockService.getAvailableBiometrics();
    notifyListeners();
  }

  Future<void> toggleLockEnabled(bool value) async {
    if (value) {
      // Verify owner identity before enabling or disabling the lock
      final auth = await FaceLockService.authenticateOwner();
      _lastResult = auth;
      if (!auth.isVerified) {
        notifyListeners();
        return;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, value);
    _isLockEnabled = value;
    _isSessionUnlocked = !value;
    notifyListeners();
  }

  /// Launches the phone's real Hardware Face Unlock / Fingerprint scanner.
  Future<bool> scanAndVerifyFace() async {
    _isProcessing = true;
    notifyListeners();

    _enrolledTypes = await FaceLockService.getAvailableBiometrics();
    final result = await FaceLockService.authenticateOwner();
    _lastResult = result;

    if (result.isVerified) {
      _isSessionUnlocked = true;
    }

    _isProcessing = false;
    notifyListeners();
    return result.isVerified;
  }

  void lockSession() {
    _isSessionUnlocked = false;
    _lastResult = null;
    notifyListeners();
  }
}