import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class BiometricAuthResult {
  final bool isVerified;
  final String message;
  final List<BiometricType> availableTypes;

  const BiometricAuthResult({
    required this.isVerified,
    required this.message,
    this.availableTypes = const [],
  });
}

class FaceLockService {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// Checks what hardware biometrics are enrolled on the device.
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      final canCheck =
          await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
      if (!canCheck) return [];
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  /// Triggers the native OS Face Unlock / Fingerprint dialog.
  static Future<BiometricAuthResult> authenticateOwner() async {
    try {
      final isSupported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      final available = await getAvailableBiometrics();

      if (!isSupported && !canCheck) {
        return const BiometricAuthResult(
          isVerified: false,
          message:
          'No biometric sensor or screen lock is set up on this phone. Please enable Fingerprint or Face Unlock in your phone Settings.',
        );
      }

      final bool didAuthenticate = await _auth.authenticate(
        localizedReason:
        'Verify your Fingerprint or Face ID to unlock your JanRaksha Medical Vault',
      );

      if (didAuthenticate) {
        return BiometricAuthResult(
          isVerified: true,
          availableTypes: available,
          message:
          'Owner identity verified via Hardware Biometric Enclave! Vault unlocked.',
        );
      } else {
        return BiometricAuthResult(
          isVerified: false,
          availableTypes: available,
          message: 'Biometric verification cancelled or did not match owner.',
        );
      }
    } on PlatformException catch (e) {
      return BiometricAuthResult(
        isVerified: false,
        message: 'Biometric error: ${e.message ?? "Authentication failed"}',
      );
    } catch (_) {
      return const BiometricAuthResult(
        isVerified: false,
        message: 'Could not launch hardware biometric scanner.',
      );
    }
  }
}