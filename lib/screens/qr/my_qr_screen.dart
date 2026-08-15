import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/theme.dart';
import '../../../core/constants.dart';
import '../../../services/qr_service.dart';
import '../../../models/user_model.dart';

class MyQrScreen extends StatelessWidget {
  const MyQrScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userModel;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My QR Code'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () =>
                Navigator.pushNamed(context, AppConstants.scanQrRoute),
            tooltip: 'Scan Someone\'s QR',
          ),
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : _QrBody(user: user),
    );
  }
}

class _QrBody extends StatelessWidget {
  final UserModel user;
  const _QrBody({required this.user});

  bool get _isProfileComplete =>
      user.bloodGroup.isNotEmpty && user.emergencyContactPhone.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final qrData = QrService.generatePayload(user);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // ── Incomplete Warning ─────────────────────────────
          if (!_isProfileComplete) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber,
                      color: Colors.orange, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Add your blood group and emergency contact to make your QR code useful.',
                      style: TextStyle(
                          color: Colors.orange.shade700, fontSize: 12),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(
                        context, AppConstants.editProfileRoute),
                    child: const Text('Fill Now',
                        style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // ── Name + Blood Group Header ──────────────────────
          Text(user.name,
              style: Theme.of(context).textTheme.headlineMedium),
          if (user.bloodGroup.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.errorColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '🩸 Blood Group: ${user.bloodGroup}',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15),
              ),
            ),
          ],
          const SizedBox(height: 28),

          // ── QR Code ───────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 240,
                  errorCorrectionLevel: QrErrorCorrectLevel.M,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: AppTheme.primaryColor,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.successColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Works Offline — No Internet Needed',
                      style: TextStyle(
                          color: AppTheme.successColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── What's encoded ────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📋 Encoded in this QR',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                      fontSize: 13),
                ),
                const SizedBox(height: 10),
                _EncodedItem('Name', user.name),
                _EncodedItem('Blood Group',
                    user.bloodGroup.isEmpty ? 'Not set' : user.bloodGroup),
                _EncodedItem('Allergies',
                    user.allergies.isEmpty ? 'None' : user.allergies.join(', ')),
                _EncodedItem('Medications',
                    user.medications.isEmpty ? 'None' : user.medications.join(', ')),
                _EncodedItem('Conditions',
                    user.conditions.isEmpty ? 'None' : user.conditions.join(', ')),
                _EncodedItem('Emergency Contact',
                    user.emergencyContactName.isEmpty ? 'Not set' : '${user.emergencyContactName} (${user.emergencyContactRelation})'),
                _EncodedItem('Contact Phone',
                    user.emergencyContactPhone.isEmpty ? 'Not set' : user.emergencyContactPhone),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Show QR to others tip ─────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppTheme.accentColor.withValues(alpha: 0.25)),
            ),
            child: const Row(
              children: [
                Icon(Icons.tips_and_updates_outlined,
                    color: AppTheme.accentColor, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Save a screenshot of this QR. Emergency responders can scan it instantly without needing the app.',
                    style: TextStyle(
                        color: AppTheme.accentColor, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Scan Someone Else ─────────────────────────────
          OutlinedButton.icon(
            onPressed: () =>
                Navigator.pushNamed(context, AppConstants.scanQrRoute),
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Scan Someone Else\'s QR'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              side: const BorderSide(
                  color: AppTheme.primaryColor, width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _EncodedItem extends StatelessWidget {
  final String label;
  final String value;
  const _EncodedItem(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text('$label:',
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}