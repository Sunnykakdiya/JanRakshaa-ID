import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/face_lock_provider.dart';

class FaceLockScreen extends StatelessWidget {
  final String? redirectRoute;

  const FaceLockScreen({super.key, this.redirectRoute});


  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FaceLockProvider>();
    final result = provider.lastResult;
    final isGatekeeper = redirectRoute != null;

    // Fixed: Single clean check for enrolled sensors
    final bool hasFingerprint = provider.enrolledTypes.contains(BiometricType.fingerprint) ||
        provider.enrolledTypes.contains(BiometricType.face);

    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      appBar: AppBar(
        title: Text(
          isGatekeeper
              ? 'Verify Identity to Unlock'
              : 'Biometric Vault (Face & Fingerprint)',
        ),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!isGatekeeper) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.fingerprint_rounded,
                          color: Color(0xFF818CF8), size: 28),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hardware Biometric Vault',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Restrict private medical records to enrolled Face ID & Fingerprints only',
                            style:
                            TextStyle(fontSize: 11.5, color: Colors.white60),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: provider.isLockEnabled,
                      activeThumbColor: const Color(0xFF00F5D4),
                      onChanged: (val) => provider.toggleLockEnabled(val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],

            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.35),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    isGatekeeper
                        ? 'Owner Authentication Required'
                        : '1-to-Many Hardware Biometric Gate',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Uses your device’s Secure Enclave to match your registered Face Unlock or Fingerprint(s).',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _SensorBadge(
                        icon: Icons.fingerprint_rounded,
                        label: 'Biometric Sensor',
                        active: hasFingerprint || provider.enrolledTypes.isEmpty,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton.icon(
                    onPressed: provider.isProcessing
                        ? null
                        : () async {
                      final verified = await provider.scanAndVerifyFace();
                      if (verified &&
                          isGatekeeper &&
                          context.mounted) {
                        Navigator.pushReplacementNamed(
                            context, redirectRoute!);
                      }
                    },
                    icon: const Icon(Icons.verified_user_rounded),
                    label: Text(
                      provider.isProcessing
                          ? 'Verifying Biometrics...'
                          : 'Authenticate Hardware Biometrics',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00B4D8),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.group_add_rounded,
                      color: Color(0xFF00F5D4), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '1-to-Many Trusted Family Support',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'You can register up to 5 fingerprints or multiple faces in your phone’s Settings so trusted family members can also unlock your vault.',
                          style:
                          TextStyle(color: Colors.white60, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (result != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: result.isVerified
                        ? AppTheme.successColor
                        : AppTheme.errorColor,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      result.isVerified
                          ? Icons.check_circle_rounded
                          : Icons.error_outline_rounded,
                      color: result.isVerified
                          ? AppTheme.successColor
                          : AppTheme.errorColor,
                      size: 26,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        result.message,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


class _SensorBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;

  const _SensorBadge({
    required this.icon,
    required this.label,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF00F5D4) : Colors.white38;
    return Column(
      children: [
        Container(
          width: 78,
          height: 78,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.12),
            border: Border.all(color: color, width: 2),
          ),
          child: Icon(icon, color: color, size: 38),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}