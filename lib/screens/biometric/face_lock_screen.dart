import 'dart:io';
import 'package:flutter/material.dart';
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

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
            isGatekeeper ? 'Verify Face to Unlock' : 'Face Biometric Lock'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Enable / Disable Toggle Card (Hidden in Gatekeeper mode) ──
            if (!isGatekeeper) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.indigo.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.lock_person,
                          color: Colors.indigo, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Protect My QR ID',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          Text(
                            'Require ML Kit face liveness check before opening QR ID',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: provider.isLockEnabled,
                      activeThumbColor: Colors.indigo,
                      onChanged: (val) => provider.toggleLockEnabled(val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ── Scanner Hub Card ───────────────────────────────────
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    isGatekeeper
                        ? 'Biometric Authentication Required'
                        : 'ML Kit Face Liveness Check',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Look straight at the front camera with both eyes clearly open.',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Face Preview or Icon
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.indigo.withValues(alpha: 0.08),
                      border: Border.all(
                        color: result == null
                            ? Colors.indigo
                            : (result.isVerified
                            ? AppTheme.successColor
                            : AppTheme.errorColor),
                        width: 3,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: provider.lastImagePath != null
                        ? Image.file(
                      File(provider.lastImagePath!),
                      fit: BoxFit.cover,
                    )
                        : const Icon(
                      Icons.face_retouching_natural,
                      size: 72,
                      color: Colors.indigo,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Scan Button
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
                    icon: provider.isProcessing
                        ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                        : const Icon(Icons.camera_front),
                    label: Text(
                      provider.isProcessing
                          ? 'Analyzing Face Liveness...'
                          : 'Scan Face Now',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Liveness Telemetry Result Card ─────────────────────
            if (result != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: result.isVerified
                        ? AppTheme.successColor
                        : AppTheme.errorColor,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          result.isVerified
                              ? Icons.verified_user
                              : Icons.gpp_bad,
                          color: result.isVerified
                              ? AppTheme.successColor
                              : AppTheme.errorColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            result.isVerified
                                ? 'Liveness Check Passed'
                                : 'Verification Failed',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: result.isVerified
                                  ? AppTheme.successColor
                                  : AppTheme.errorColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(result.message, style: const TextStyle(fontSize: 13)),
                    if (result.leftEyeOpen > 0 || result.rightEyeOpen > 0) ...[
                      const Divider(height: 24),
                      _MetricRow(
                        label: 'Left Eye Open Probability',
                        value:
                        '${(result.leftEyeOpen * 100).toStringAsFixed(0)}%',
                        passed: result.leftEyeOpen >= 0.75,
                      ),
                      const SizedBox(height: 8),
                      _MetricRow(
                        label: 'Right Eye Open Probability',
                        value:
                        '${(result.rightEyeOpen * 100).toStringAsFixed(0)}%',
                        passed: result.rightEyeOpen >= 0.75,
                      ),
                    ],
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

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final bool passed;

  const _MetricRow({
    required this.label,
    required this.value,
    required this.passed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: (passed ? AppTheme.successColor : Colors.orange)
                .withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: passed ? AppTheme.successColor : Colors.orange,
            ),
          ),
        ),
      ],
    );
  }
}