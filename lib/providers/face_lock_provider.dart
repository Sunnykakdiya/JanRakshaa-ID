import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/face_lock_service.dart';

class FaceLockProvider extends ChangeNotifier {
  static const String _prefKey = 'face_biometric_lock_enabled';
  final ImagePicker _picker = ImagePicker();

  bool _isLockEnabled = false;
  bool _isSessionUnlocked = false;
  bool _isProcessing = false;
  String? _lastImagePath;
  FaceLivenessResult? _lastResult;

  bool get isLockEnabled => _isLockEnabled;
  bool get isSessionUnlocked => _isSessionUnlocked;
  bool get isProcessing => _isProcessing;
  String? get lastImagePath => _lastImagePath;
  FaceLivenessResult? get lastResult => _lastResult;

  FaceLockProvider() {
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    _isLockEnabled = prefs.getBool(_prefKey) ?? false;
    notifyListeners();
  }

  Future<void> toggleLockEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, value);
    _isLockEnabled = value;
    if (!value) {
      _isSessionUnlocked = true;
    } else {
      _isSessionUnlocked = false;
    }
    notifyListeners();
  }

  /// Captures a front-camera selfie and runs ML Kit Face Liveness verification.
  Future<bool> scanAndVerifyFace() async {
    _isProcessing = true;
    _lastResult = null;
    notifyListeners();

    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 85,
      );

      if (photo == null) {
        _isProcessing = false;
        notifyListeners();
        return false;
      }

      _lastImagePath = photo.path;
      final result = await FaceLockService.verifyLivenessFromFile(photo.path);
      _lastResult = result;

      if (result.isVerified) {
        _isSessionUnlocked = true;
      }

      _isProcessing = false;
      notifyListeners();
      return result.isVerified;
    } catch (e) {
      _lastResult = const FaceLivenessResult(
        isVerified: false,
        message: 'Camera access error. Check camera permissions.',
      );
      _isProcessing = false;
      notifyListeners();
      return false;
    }
  }

  void lockSession() {
    _isSessionUnlocked = false;
    _lastResult = null;
    notifyListeners();
  }
}