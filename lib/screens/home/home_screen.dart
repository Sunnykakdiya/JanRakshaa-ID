import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../models/user_model.dart';
import '../../models/vitals_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/vitals_provider.dart';
import '../../providers/face_lock_provider.dart';
import '../../services/qr_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _profilePhotoPath;
  Set<String> _takenMedsToday = {};
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadLocalEnhancements();
  }

  Future<void> _loadLocalEnhancements() async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey =
        'meds_${DateTime.now().year}_${DateTime.now().month}_${DateTime.now().day}';
    if (!mounted) return;
    setState(() {
      _profilePhotoPath = prefs.getString('user_profile_photo_path');
      _takenMedsToday = (prefs.getStringList(todayKey) ?? []).toSet();
    });
  }

  Future<void> _pickProfilePhoto() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Update Medical Passport Photo',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppTheme.primaryColor,
                  child: Icon(Icons.camera_alt, color: Colors.white),
                ),
                title: const Text('Take a Photo'),
                subtitle: const Text('Use front or back camera'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final file = await _picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 85,
                  );
                  if (file != null) _savePhotoPath(file.path);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppTheme.secondaryColor,
                  child: Icon(Icons.photo_library, color: Colors.white),
                ),
                title: const Text('Choose from Gallery'),
                subtitle: const Text('Select an existing portrait photo'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final file = await _picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 85,
                  );
                  if (file != null) _savePhotoPath(file.path);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _savePhotoPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_profile_photo_path', path);
    if (!mounted) return;
    setState(() => _profilePhotoPath = path);
  }

  Future<void> _toggleMedDose(String med) async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey =
        'meds_${DateTime.now().year}_${DateTime.now().month}_${DateTime.now().day}';
    setState(() {
      if (_takenMedsToday.contains(med)) {
        _takenMedsToday.remove(med);
      } else {
        _takenMedsToday.add(med);
      }
    });
    await prefs.setStringList(todayKey, _takenMedsToday.toList());
  }

  /// Central gatekeeper: If Face Lock is enabled and session is locked,
  /// requires ML Kit Face Liveness before opening private routes.
  void _navigateProtected(BuildContext context, String targetRoute) {
    final faceLock = context.read<FaceLockProvider>();
    if (faceLock.isLockEnabled && !faceLock.isSessionUnlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Patient Vault is locked. Verify your live face to access private medical records.',
          ),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pushNamed(
        context,
        AppConstants.faceLockRoute,
        arguments: targetRoute,
      );
      return;
    }
    Navigator.pushNamed(context, targetRoute);
  }

  /// Instant Apple-Wallet style Bottom Sheet for First-Responder Offline QR
  void _showOfflineQrModal(BuildContext context, UserModel? u) {
    final qrPayload = u != null
        ? QrService.generatePayload(u)
        : '{"app":"JanRaksha","n":"Unconfigured"}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.offline_bolt,
                        color: AppTheme.successColor, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'OFFLINE FIRST-RESPONDER PASS',
                      style: TextStyle(
                        color: AppTheme.successColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                u?.name.isNotEmpty == true ? u!.name : 'Emergency Patient Pass',
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              const Text(
                'Paramedics can scan this code without internet to view Blood Group, Allergies, and ICE Contact.',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade200, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: qrPayload,
                  version: QrVersions.auto,
                  size: 200,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _navigateProtected(context, AppConstants.qrRoute);
                      },
                      icon: const Icon(Icons.fullscreen, size: 18),
                      label: const Text('Full QR Screen'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Done'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user ??
        context.watch<AuthProvider>().userModel;
    final vitals = context.watch<VitalsProvider>().entries;
    final latestVital = vitals.isNotEmpty ? vitals.first : null;
    final faceLock = context.watch<FaceLockProvider>();

    // Determine if sensitive clinical vault data should be masked
    final bool isVaultLocked =
        faceLock.isLockEnabled && !faceLock.isSessionUnlocked;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: _buildClinicalAppBar(context, faceLock, isVaultLocked),
      bottomNavigationBar: _ClinicalBottomBar(
        isVaultLocked: isVaultLocked,
        onQrTap: () => _showOfflineQrModal(context, user),
        onVitalsTap: () => _navigateProtected(context, AppConstants.vitalsRoute),
        onSosTap: () => Navigator.pushNamed(context, AppConstants.sosRoute),
        onProfileTap: () =>
            _navigateProtected(context, AppConstants.profileRoute),
        onEditTap: () =>
            _navigateProtected(context, AppConstants.editProfileRoute),
      ),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── 1. Mode Switcher Banner (Responder vs Vault Mode) ──
                  _VaultStatusBanner(
                    isLockEnabled: faceLock.isLockEnabled,
                    isVaultLocked: isVaultLocked,
                    onToggleVault: () {
                      if (!faceLock.isLockEnabled) {
                        Navigator.pushNamed(
                            context, AppConstants.faceLockRoute);
                      } else if (isVaultLocked) {
                        faceLock.scanAndVerifyFace();
                      } else {
                        faceLock.lockSession();
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // ── 2. Swiss Clinical Medical Passport Card ────────────
                  _MedicalPassportCard(
                    user: user,
                    photoPath: _profilePhotoPath,
                    isVaultLocked: isVaultLocked,
                    onAvatarTap: isVaultLocked
                        ? () => _navigateProtected(
                        context, AppConstants.editProfileRoute)
                        : _pickProfilePhoto,
                    onShowQr: () => _showOfflineQrModal(context, user),
                    onUnlockTap: () => faceLock.scanAndVerifyFace(),
                  ),
                  const SizedBox(height: 16),

                  // ── 3. Health Readiness & Live Vitals Telemetry ────────
                  _ClinicalTelemetryCard(
                    user: user,
                    latestVital: latestVital,
                    isVaultLocked: isVaultLocked,
                    onTap: () =>
                        _navigateProtected(context, AppConstants.vitalsRoute),
                  ),
                  const SizedBox(height: 16),

                  // ── 4. Daily Medication Checklist (Hidden when locked) ─
                  if (user != null && user.medications.isNotEmpty) ...[
                    _MedicationAdherenceCard(
                      medications: user.medications,
                      takenMeds: _takenMedsToday,
                      isVaultLocked: isVaultLocked,
                      onToggle: _toggleMedDose,
                      onUnlockTap: () => faceLock.scanAndVerifyFace(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── 5. Section Header ──────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Clinical AI & Emergency Modules',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '8 PHASES READY',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── 6. Responsive Zero-Overflow Clinical Grid ──────────
                  _ClinicalModulesGrid(
                    isVaultLocked: isVaultLocked,
                    onNavigateProtected: (route) =>
                        _navigateProtected(context, route),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildClinicalAppBar(
      BuildContext context,
      FaceLockProvider faceLock,
      bool isVaultLocked,
      ) {
    return AppBar(
      backgroundColor: Colors.white,
      foregroundColor: AppTheme.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 1,
      titleSpacing: 16,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.health_and_safety,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'JanRaksha ID',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'AI Medical Identity & Emergency Suite',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(
            isVaultLocked ? Icons.lock_person : Icons.verified_user_outlined,
            color: isVaultLocked ? Colors.indigo : AppTheme.successColor,
            size: 22,
          ),
          tooltip: 'Face Biometric Vault Settings',
          onPressed: () =>
              Navigator.pushNamed(context, AppConstants.faceLockRoute),
        ),
        IconButton(
          icon: const Icon(Icons.auto_awesome,
              color: AppTheme.primaryColor, size: 22),
          tooltip: 'Gemini AI Settings',
          onPressed: () =>
              Navigator.pushNamed(context, AppConstants.geminiSettingsRoute),
        ),
        IconButton(
          icon: const Icon(Icons.logout_rounded,
              color: AppTheme.textSecondary, size: 21),
          tooltip: 'Sign Out',
          onPressed: () => context.read<AuthProvider>().signOut(),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// 1. VAULT STATUS BANNER (EXPLAINS PHASE 7 BIOMETRIC SECURITY)
// ══════════════════════════════════════════════════════════════════════════
class _VaultStatusBanner extends StatelessWidget {
  final bool isLockEnabled;
  final bool isVaultLocked;
  final VoidCallback onToggleVault;

  const _VaultStatusBanner({
    required this.isLockEnabled,
    required this.isVaultLocked,
    required this.onToggleVault,
  });

  @override
  Widget build(BuildContext context) {
    final Color accent = !isLockEnabled
        ? Colors.blueGrey
        : (isVaultLocked ? Colors.indigo : AppTheme.successColor);

    final String title = !isLockEnabled
        ? 'Biometric Privacy Shield: OFF'
        : (isVaultLocked
        ? 'First-Responder Mode Active (Vault Locked)'
        : 'Patient Clinical Vault Unlocked');

    final String subtitle = !isLockEnabled
        ? 'Tap to enable Phase 7 ML Kit Face Lock for private records'
        : (isVaultLocked
        ? 'Emergency info visible · Private records require live face scan'
        : 'All medical records & edit tools unlocked for this session');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(
            !isLockEnabled
                ? Icons.shield_outlined
                : (isVaultLocked ? Icons.lock_outline : Icons.lock_open),
            color: accent,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: accent,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onToggleVault,
            style: TextButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              !isLockEnabled
                  ? 'Setup'
                  : (isVaultLocked ? 'Unlock' : 'Lock Now'),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// 2. SWISS CLINICAL MEDICAL PASSPORT CARD (OVERFLOW-PROOF)
// ══════════════════════════════════════════════════════════════════════════
class _MedicalPassportCard extends StatelessWidget {
  final UserModel? user;
  final String? photoPath;
  final bool isVaultLocked;
  final VoidCallback onAvatarTap;
  final VoidCallback onShowQr;
  final VoidCallback onUnlockTap;

  const _MedicalPassportCard({
    required this.user,
    required this.photoPath,
    required this.isVaultLocked,
    required this.onAvatarTap,
    required this.onShowQr,
    required this.onUnlockTap,
  });

  @override
  Widget build(BuildContext context) {
    final u = user;
    final name =
    (u != null && u.name.isNotEmpty) ? u.name : 'Unconfigured Patient';
    final blood = (u != null && u.bloodGroup.isNotEmpty) ? u.bloodGroup : 'N/A';
    final gender = (u != null && u.gender.isNotEmpty) ? u.gender : 'Not Set';
    final dob =
    (u != null && u.dateOfBirth.isNotEmpty) ? u.dateOfBirth : 'Not Set';
    final ice = (u != null && u.emergencyContactPhone.isNotEmpty)
        ? '${u.emergencyContactName} (${u.emergencyContactPhone})'
        : 'Tap Edit to add Emergency Contact';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Deep Navy Clinical Header Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(19)),
            ),
            child: Row(
              children: [
                const Icon(Icons.medical_services_outlined,
                    color: Colors.cyanAccent, size: 16),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'EMERGENCY MEDICAL PASSPORT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'BLOOD: $blood',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main Identity Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Patient Portrait Photo
                    GestureDetector(
                      onTap: onAvatarTap,
                      child: Stack(
                        children: [
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppTheme.primaryColor
                                    .withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                              image: (photoPath != null &&
                                  File(photoPath!).existsSync())
                                  ? DecorationImage(
                                image: FileImage(File(photoPath!)),
                                fit: BoxFit.cover,
                              )
                                  : null,
                            ),
                            child: (photoPath == null ||
                                !File(photoPath!).existsSync())
                                ? const Icon(Icons.person_outline,
                                color: AppTheme.primaryColor, size: 32)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt,
                                  size: 10, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Patient Demographics
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Sex: $gender   ·   DOB: $dob',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.phone_in_talk,
                                  size: 13, color: AppTheme.errorColor),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  'ICE: $ice',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.errorColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1),
                ),

                // Critical Medical Tags (Allergies Always Visible, Meds/Cond Masked if Vault Locked)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _PassportBadge(
                      icon: Icons.warning_amber_rounded,
                      label: u != null && u.allergies.isNotEmpty
                          ? 'Allergies: ${u.allergies.join(", ")}'
                          : 'No Known Allergies',
                      color: Colors.orange.shade800,
                    ),
                    _PassportBadge(
                      icon: isVaultLocked
                          ? Icons.lock_outline
                          : Icons.medication_outlined,
                      label: isVaultLocked
                          ? 'Medications: •••• (Locked)'
                          : 'Meds: ${u?.medications.length ?? 0} Active',
                      color:
                      isVaultLocked ? Colors.indigo : AppTheme.primaryColor,
                    ),
                    _PassportBadge(
                      icon: isVaultLocked
                          ? Icons.lock_outline
                          : Icons.monitor_heart_outlined,
                      label: isVaultLocked
                          ? 'Conditions: •••• (Locked)'
                          : 'Conditions: ${u?.conditions.length ?? 0}',
                      color: isVaultLocked ? Colors.indigo : Colors.teal,
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Action Buttons Row
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onShowQr,
                        icon: const Icon(Icons.qr_code_2, size: 18),
                        label: const Text(
                          'Offline Responder QR',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.textPrimary,
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            Navigator.pushNamed(context, AppConstants.sosRoute),
                        icon: const Icon(Icons.emergency_share, size: 17),
                        label: const Text(
                          'Emergency SOS',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.errorColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PassportBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _PassportBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// 3. HEALTH READINESS & LIVE VITALS TELEMETRY CARD
// ══════════════════════════════════════════════════════════════════════════
class _ClinicalTelemetryCard extends StatelessWidget {
  final UserModel? user;
  final VitalsEntry? latestVital;
  final bool isVaultLocked;
  final VoidCallback onTap;

  const _ClinicalTelemetryCard({
    required this.user,
    required this.latestVital,
    required this.isVaultLocked,
    required this.onTap,
  });

  int _calculateScore() {
    int score = 60;
    if (user != null) {
      if (user!.bloodGroup.isNotEmpty) score += 10;
      if (user!.emergencyContactPhone.isNotEmpty) score += 10;
    }
    if (latestVital != null) {
      if (latestVital!.alertLevel == 'normal') score += 20;
      if (latestVital!.alertLevel == 'warning') score += 8;
      if (latestVital!.alertLevel == 'danger') score -= 15;
    }
    return score.clamp(25, 100);
  }

  @override
  Widget build(BuildContext context) {
    final score = _calculateScore();
    final scoreColor = score >= 80
        ? AppTheme.successColor
        : (score >= 60 ? Colors.orange : AppTheme.errorColor);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            // Score Gauge
            SizedBox(
              width: 58,
              height: 58,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 6,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$score',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: scoreColor,
                        ),
                      ),
                      const Text(
                        'INDEX',
                        style: TextStyle(
                          fontSize: 7,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),

            // Telemetry Readings
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Vitals Telemetry',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        isVaultLocked ? '🔒 Locked' : 'Open Charts →',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isVaultLocked
                              ? Colors.indigo
                              : AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _TelemetryItem(
                          label: 'Heart Rate',
                          value: isVaultLocked
                              ? '•••'
                              : (latestVital != null
                              ? '${latestVital!.heartRate} bpm'
                              : '-- bpm'),
                          color: Colors.redAccent,
                        ),
                      ),
                      Expanded(
                        child: _TelemetryItem(
                          label: 'Blood Press.',
                          value: isVaultLocked
                              ? '••/••'
                              : (latestVital != null
                              ? '${latestVital!.systolicBP}/${latestVital!.diastolicBP}'
                              : '--/--'),
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      Expanded(
                        child: _TelemetryItem(
                          label: 'Glucose',
                          value: isVaultLocked
                              ? '•••'
                              : (latestVital != null
                              ? '${latestVital!.glucoseLevel}'
                              : '--'),
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TelemetryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _TelemetryItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// 4. MEDICATION ADHERENCE CARD (RESPECTS VAULT LOCK)
// ══════════════════════════════════════════════════════════════════════════
class _MedicationAdherenceCard extends StatelessWidget {
  final List<String> medications;
  final Set<String> takenMeds;
  final bool isVaultLocked;
  final ValueChanged<String> onToggle;
  final VoidCallback onUnlockTap;

  const _MedicationAdherenceCard({
    required this.medications,
    required this.takenMeds,
    required this.isVaultLocked,
    required this.onToggle,
    required this.onUnlockTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.medication_liquid,
                  color: AppTheme.primaryColor, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Daily Medication Schedule',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                isVaultLocked
                    ? 'Vault Locked'
                    : '${takenMeds.length}/${medications.length} Taken',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isVaultLocked ? Colors.indigo : AppTheme.successColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (isVaultLocked)
            InkWell(
              onTap: onUnlockTap,
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.indigo.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock_person, color: Colors.indigo, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Medications hidden in Responder Mode. Tap to verify face.',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.indigo,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: medications.map((med) {
                final isTaken = takenMeds.contains(med);
                return FilterChip(
                  selected: isTaken,
                  label: Text(med),
                  selectedColor: AppTheme.successColor.withValues(alpha: 0.16),
                  checkmarkColor: AppTheme.successColor,
                  labelStyle: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    decoration: isTaken ? TextDecoration.lineThrough : null,
                    color:
                    isTaken ? AppTheme.successColor : AppTheme.textPrimary,
                  ),
                  onSelected: (_) => onToggle(med),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// 5. RESPONSIVE CLINICAL MODULES GRID (ZERO OVERFLOW)
// ══════════════════════════════════════════════════════════════════════════
class _ClinicalModulesGrid extends StatelessWidget {
  final bool isVaultLocked;
  final ValueChanged<String> onNavigateProtected;

  const _ClinicalModulesGrid({
    required this.isVaultLocked,
    required this.onNavigateProtected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Row 1: Primary AI Diagnostic Modules
        Row(
          children: [
            Expanded(
              child: _ClinicalModuleTile(
                title: 'Symptom Checker',
                subtitle: 'Gemini 1.5 Triage',
                phase: 'PHASE 3',
                icon: Icons.psychology_outlined,
                color: AppTheme.primaryColor,
                isLocked: false,
                onTap: () => Navigator.pushNamed(
                    context, AppConstants.symptomCheckerRoute),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ClinicalModuleTile(
                title: 'Drug Interactions',
                subtitle: 'Safety Conflict AI',
                phase: 'PHASE 3',
                icon: Icons.science_outlined,
                color: Colors.orange.shade800,
                isLocked: false,
                onTap: () =>
                    Navigator.pushNamed(context, AppConstants.drugCheckerRoute),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Row 2: Protected Clinical Records (OCR Scanner & Vitals AI)
        Row(
          children: [
            Expanded(
              child: _ClinicalModuleTile(
                title: 'OCR Doc Scanner',
                subtitle: 'Lab & Rx Extraction',
                phase: 'PHASE 4',
                icon: Icons.document_scanner_outlined,
                color: Colors.teal,
                isLocked: isVaultLocked,
                onTap: () => onNavigateProtected(AppConstants.docScannerRoute),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ClinicalModuleTile(
                title: 'Vitals AI Tracker',
                subtitle: 'Anomaly Detection',
                phase: 'PHASE 5',
                icon: Icons.monitor_heart_outlined,
                color: Colors.purple,
                isLocked: isVaultLocked,
                onTap: () => onNavigateProtected(AppConstants.vitalsRoute),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Row 3: Emergency Dispatch & Hospital Locator (Always Unlocked)
        Row(
          children: [
            Expanded(
              child: _ClinicalModuleTile(
                title: 'Voice SOS Beacon',
                subtitle: 'Strobe + Hands-Free',
                phase: 'PHASE 6',
                icon: Icons.mic_none_rounded,
                color: AppTheme.errorColor,
                isLocked: false,
                onTap: () => Navigator.pushNamed(context, AppConstants.sosRoute),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ClinicalModuleTile(
                title: 'Hospital Finder',
                subtitle: 'Live GPS + Triage',
                phase: 'PHASE 8',
                icon: Icons.local_hospital_outlined,
                color: AppTheme.successColor,
                isLocked: false,
                onTap: () => Navigator.pushNamed(
                    context, AppConstants.hospitalFinderRoute),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Row 4: Biometric Vault & Responder QR Scanner
        Row(
          children: [
            Expanded(
              child: _ClinicalModuleTile(
                title: 'Face Biometric Lock',
                subtitle: 'ML Kit Liveness Gate',
                phase: 'PHASE 7',
                icon: Icons.face_retouching_natural,
                color: Colors.indigo,
                isLocked: false,
                onTap: () =>
                    Navigator.pushNamed(context, AppConstants.faceLockRoute),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ClinicalModuleTile(
                title: 'Scan Patient QR',
                subtitle: 'Paramedic Scanner',
                phase: 'PHASE 2',
                icon: Icons.qr_code_scanner_rounded,
                color: const Color(0xFF0F172A),
                isLocked: false,
                onTap: () =>
                    Navigator.pushNamed(context, AppConstants.scanQrRoute),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ClinicalModuleTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String phase;
  final IconData icon;
  final Color color;
  final bool isLocked;
  final VoidCallback onTap;

  const _ClinicalModuleTile({
    required this.title,
    required this.subtitle,
    required this.phase,
    required this.icon,
    required this.color,
    required this.isLocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isLocked
                        ? Colors.indigo.withValues(alpha: 0.1)
                        : color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isLocked) ...[
                        const Icon(Icons.lock, size: 9, color: Colors.indigo),
                        const SizedBox(width: 3),
                      ],
                      Text(
                        isLocked ? 'VAULT' : phase,
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: isLocked ? Colors.indigo : color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: AppTheme.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// 6. SOLID DOCKED CLINICAL NAVIGATION BAR (NEVER OVERLAPS CONTENT)
// ══════════════════════════════════════════════════════════════════════════
class _ClinicalBottomBar extends StatelessWidget {
  final bool isVaultLocked;
  final VoidCallback onQrTap;
  final VoidCallback onVitalsTap;
  final VoidCallback onSosTap;
  final VoidCallback onProfileTap;
  final VoidCallback onEditTap;

  const _ClinicalBottomBar({
    required this.isVaultLocked,
    required this.onQrTap,
    required this.onVitalsTap,
    required this.onSosTap,
    required this.onProfileTap,
    required this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _BottomNavButton(
                icon: Icons.qr_code_2_rounded,
                label: 'QR Pass',
                onTap: onQrTap,
              ),
              _BottomNavButton(
                icon: Icons.monitor_heart_outlined,
                label: isVaultLocked ? 'Vitals 🔒' : 'Vitals',
                onTap: onVitalsTap,
              ),
              GestureDetector(
                onTap: onSosTap,
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.emergency, color: Colors.white, size: 16),
                      SizedBox(width: 5),
                      Text(
                        'SOS',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _BottomNavButton(
                icon: Icons.person_outline_rounded,
                label: isVaultLocked ? 'Profile 🔒' : 'Profile',
                onTap: onProfileTap,
              ),
              _BottomNavButton(
                icon: Icons.edit_note_rounded,
                label: isVaultLocked ? 'Edit 🔒' : 'Edit ID',
                onTap: onEditTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _BottomNavButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppTheme.textPrimary, size: 20),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}