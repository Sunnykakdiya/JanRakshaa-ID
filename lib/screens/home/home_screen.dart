import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  String? _profilePhotoPath;
  Set<String> _takenMedsToday = {};
  final ImagePicker _picker = ImagePicker();

  late AnimationController _pulseController;
  late AnimationController _entranceController;

  @override
  void initState() {
    super.initState();
    _loadLocalEnhancements();

    // Continuous live animation for ECG wave, breathing orbs, and SOS pulse
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    // Staggered entrance cascade animation
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _entranceController.dispose();
    super.dispose();
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
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
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
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Update Hologram ID Photo',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF00B4D8),
                  child: Icon(Icons.camera_alt, color: Colors.white),
                ),
                title: const Text('Take a Photo',
                    style: TextStyle(color: Colors.white)),
                subtitle: const Text('Capture with front or back camera',
                    style: TextStyle(color: Colors.white60, fontSize: 12)),
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
                  backgroundColor: Color(0xFF6366F1),
                  child: Icon(Icons.photo_library, color: Colors.white),
                ),
                title: const Text('Choose from Gallery',
                    style: TextStyle(color: Colors.white)),
                subtitle: const Text('Select from your phone gallery',
                    style: TextStyle(color: Colors.white60, fontSize: 12)),
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
    HapticFeedback.lightImpact();
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

  void _navigateProtected(BuildContext context, String targetRoute) {
    HapticFeedback.lightImpact();
    final faceLock = context.read<FaceLockProvider>();
    if (faceLock.isLockEnabled && !faceLock.isSessionUnlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Biometric Vault Locked! Scan your live face to unlock private records.',
          ),
          backgroundColor: Color(0xFF4F46E5),
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

  Widget _buildStaggered(int index, Widget child) {
    final start = (index * 0.12).clamp(0.0, 0.6);
    final end = (start + 0.4).clamp(0.0, 1.0);
    final curved = CurvedAnimation(
      parent: _entranceController,
      curve: Interval(start, end, curve: Curves.easeOutBack),
    );
    return AnimatedBuilder(
      animation: curved,
      builder: (context, c) => Opacity(
        opacity: curved.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 28 * (1 - curved.value)),
          child: c,
        ),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user ??
        context.watch<AuthProvider>().userModel;
    final vitals = context.watch<VitalsProvider>().entries;
    final latestVital = vitals.isNotEmpty ? vitals.first : null;
    final faceLock = context.watch<FaceLockProvider>();

    final bool isVaultLocked =
        faceLock.isLockEnabled && !faceLock.isSessionUnlocked;

    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      bottomNavigationBar: _DynamicGlassBottomDock(
        pulseAnimation: _pulseController,
        isVaultLocked: isVaultLocked,
        onQrTap: () => _navigateProtected(context, AppConstants.qrRoute),
        onVitalsTap: () => _navigateProtected(context, AppConstants.vitalsRoute),
        onSosTap: () {
          HapticFeedback.heavyImpact();
          Navigator.pushNamed(context, AppConstants.sosRoute);
        },
        onProfileTap: () =>
            _navigateProtected(context, AppConstants.profileRoute),
        onEditTap: () =>
            _navigateProtected(context, AppConstants.editProfileRoute),
      ),
      body: Stack(
        children: [
          // ── 1. Animated Breathing Cyber-Medical Background Orbs ────
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, _) {
              final wave = math.sin(_pulseController.value * 2 * math.pi);
              return Stack(
                children: [
                  Positioned(
                    top: -60 + (wave * 18),
                    left: -40 + (wave * 12),
                    child: _GlowOrb(
                      size: 260,
                      color: const Color(0xFF00B4D8).withValues(alpha: 0.22),
                    ),
                  ),
                  Positioned(
                    top: 220 - (wave * 20),
                    right: -70,
                    child: _GlowOrb(
                      size: 280,
                      color: const Color(0xFF4F46E5).withValues(alpha: 0.18),
                    ),
                  ),
                  Positioned(
                    bottom: 80 + (wave * 15),
                    left: 40,
                    child: _GlowOrb(
                      size: 220,
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    ),
                  ),
                ],
              );
            },
          ),

          // ── 2. Foreground Scrollable Command Console ───────────────
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _TopDynamicHeader(
                    user: user,
                    photoPath: _profilePhotoPath,
                    pulseAnimation: _pulseController,
                    onPhotoTap: _pickProfilePhoto,
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 32),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Biometric Security Mode Switcher Pill
                      _buildStaggered(
                        0,
                        _BiometricShieldPill(
                          isLockEnabled: faceLock.isLockEnabled,
                          isVaultLocked: isVaultLocked,
                          onTap: () {
                            HapticFeedback.mediumImpact();
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
                      ),
                      const SizedBox(height: 14),

                      // Interactive 3D Flip Hologram Medical ID Card
                      _buildStaggered(
                        1,
                        _Interactive3DMedicalPass(
                          user: user,
                          photoPath: _profilePhotoPath,
                          isVaultLocked: isVaultLocked,
                          pulseAnimation: _pulseController,
                          onAvatarTap: _pickProfilePhoto,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Live Animated ECG Waveform & Vitals Telemetry Card
                      _buildStaggered(
                        2,
                        _LiveEcgTelemetryCard(
                          user: user,
                          latestVital: latestVital,
                          isVaultLocked: isVaultLocked,
                          ecgAnimation: _pulseController,
                          onTap: () => _navigateProtected(
                              context, AppConstants.vitalsRoute),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Interactive Daily Medication Pill Tracker
                      if (user != null && user.medications.isNotEmpty) ...[
                        _buildStaggered(
                          3,
                          _DynamicMedicationDeck(
                            medications: user.medications,
                            takenMeds: _takenMedsToday,
                            isVaultLocked: isVaultLocked,
                            onToggle: _toggleMedDose,
                            onUnlockTap: () => faceLock.scanAndVerifyFace(),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Section Header with Live Pulse Indicator
                      _buildStaggered(
                        4,
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text(
                                'AI Neural & Emergency Matrix',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981)
                                    .withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFF10B981)
                                      .withValues(alpha: 0.4),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.bolt,
                                      size: 12, color: Color(0xFF34D399)),
                                  SizedBox(width: 3),
                                  Text(
                                    'ALL SYSTEMS ONLINE',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF34D399),
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Dynamic Pressable Bento Grid
                      _buildStaggered(
                        5,
                        _DynamicBentoMatrix(
                          isVaultLocked: isVaultLocked,
                          onNavigateProtected: (route) =>
                              _navigateProtected(context, route),
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// AMBIENT GLOW ORB & SPRING-PHYSICS PRESSABLE WRAPPER
// ══════════════════════════════════════════════════════════════════════════
class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;
  const _GlowOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, Colors.transparent],
          ),
        ),
      ),
    );
  }
}

class _PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _PressableScale({required this.child, required this.onTap});

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.96),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// 1. TOP DYNAMIC HEADER
// ══════════════════════════════════════════════════════════════════════════
class _TopDynamicHeader extends StatelessWidget {
  final UserModel? user;
  final String? photoPath;
  final Animation<double> pulseAnimation;
  final VoidCallback onPhotoTap;

  const _TopDynamicHeader({
    required this.user,
    required this.photoPath,
    required this.pulseAnimation,
    required this.onPhotoTap,
  });

  @override
  Widget build(BuildContext context) {
    final firstName = user?.name.split(' ').first ?? 'Commander';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: onPhotoTap,
            child: AnimatedBuilder(
              animation: pulseAnimation,
              builder: (context, child) {
                final glow =
                    (math.sin(pulseAnimation.value * 2 * math.pi) + 1) / 2;
                return Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00F5D4), Color(0xFF00BBF9)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00F5D4)
                            .withValues(alpha: 0.25 + (glow * 0.25)),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: child,
                );
              },
              child: CircleAvatar(
                radius: 21,
                backgroundColor: const Color(0xFF0F172A),
                backgroundImage:
                (photoPath != null && File(photoPath!).existsSync())
                    ? FileImage(File(photoPath!))
                    : null,
                child: (photoPath == null || !File(photoPath!).existsSync())
                    ? const Icon(Icons.person, color: Colors.white, size: 22)
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00F5D4),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Flexible(
                      child: Text(
                        'JANRAKSHA BIO-OS · LIVE',
                        style: TextStyle(
                          color: Color(0xFF00F5D4),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Hello, $firstName',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.info_outline_rounded,
                color: Colors.white70, size: 21),
            tooltip: 'Architecture & About',
            onPressed: () {
              try {
                Navigator.pushNamed(context, '/about');
              } catch (_) {}
            },
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.auto_awesome,
                color: Color(0xFF38BDF8), size: 21),
            tooltip: 'Gemini AI Settings',
            onPressed: () =>
                Navigator.pushNamed(context, AppConstants.geminiSettingsRoute),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.logout_rounded,
                color: Colors.white54, size: 20),
            tooltip: 'Sign Out',
            onPressed: () => context.read<AuthProvider>().signOut(),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// 2. BIOMETRIC SHIELD STATUS PILL
// ══════════════════════════════════════════════════════════════════════════
class _BiometricShieldPill extends StatelessWidget {
  final bool isLockEnabled;
  final bool isVaultLocked;
  final VoidCallback onTap;

  const _BiometricShieldPill({
    required this.isLockEnabled,
    required this.isVaultLocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color accent = !isLockEnabled
        ? const Color(0xFF38BDF8)
        : (isVaultLocked ? const Color(0xFFF59E0B) : const Color(0xFF10B981));

    return _PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF111827).withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              !isLockEnabled
                  ? Icons.shield_outlined
                  : (isVaultLocked
                  ? Icons.lock_person_rounded
                  : Icons.verified_user_rounded),
              color: accent,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    !isLockEnabled
                        ? 'Biometric Privacy Vault: Standby'
                        : (isVaultLocked
                        ? 'First-Responder Mode Active (Vault Locked)'
                        : 'Biometric Face Liveness Verified'),
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    !isLockEnabled
                        ? 'Tap to activate ML Kit Face Lock for private records'
                        : (isVaultLocked
                        ? 'Emergency ID visible · Private data masked (Tap to Unlock)'
                        : 'All clinical records unlocked · Tap to re-lock'),
                    style: const TextStyle(color: Colors.white60, fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                !isLockEnabled
                    ? 'SETUP'
                    : (isVaultLocked ? 'UNLOCK' : 'LOCK'),
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// 3. INTERACTIVE 3D FLIP HOLOGRAM MEDICAL ID PASS (OVERFLOW-PROOF)
// ══════════════════════════════════════════════════════════════════════════
class _Interactive3DMedicalPass extends StatefulWidget {
  final UserModel? user;
  final String? photoPath;
  final bool isVaultLocked;
  final Animation<double> pulseAnimation;
  final VoidCallback onAvatarTap;

  const _Interactive3DMedicalPass({
    required this.user,
    required this.photoPath,
    required this.isVaultLocked,
    required this.pulseAnimation,
    required this.onAvatarTap,
  });

  @override
  State<_Interactive3DMedicalPass> createState() =>
      _Interactive3DMedicalPassState();
}

class _Interactive3DMedicalPassState extends State<_Interactive3DMedicalPass>
    with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  void _toggleFlip() {
    HapticFeedback.mediumImpact();
    if (_isFront) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
    _isFront = !_isFront;
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleFlip,
      child: AnimatedBuilder(
        animation: _flipController,
        builder: (context, _) {
          final angle = _flipController.value * math.pi;
          final isShowingFront = angle <= (math.pi / 2);

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0011)
              ..rotateY(angle),
            child: isShowingFront
                ? _buildFrontCard(widget.user)
                : Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()..rotateY(math.pi),
              child: _buildBackQrCard(widget.user),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFrontCard(UserModel? u) {
    final name =
    (u != null && u.name.isNotEmpty) ? u.name : 'Complete Your Profile';
    final blood = (u != null && u.bloodGroup.isNotEmpty) ? u.bloodGroup : 'N/A';
    final gender = (u != null && u.gender.isNotEmpty) ? u.gender : 'Not Set';
    final dob =
    (u != null && u.dateOfBirth.isNotEmpty) ? u.dateOfBirth : 'Not Set';
    final ice = (u != null && u.emergencyContactPhone.isNotEmpty)
        ? '${u.emergencyContactName} (${u.emergencyContactPhone})'
        : 'Set ICE Contact in Edit Profile';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1E1B4B),
            Color(0xFF0369A1),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF38BDF8).withValues(alpha: 0.45),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: 0.28),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Header Row
          Row(
            children: [
              const Icon(Icons.contactless_rounded,
                  color: Color(0xFF00F5D4), size: 18),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'JANRAKSHA SMART HEALTH PASS',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
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
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'BLOOD: $blood',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Identity Middle Row
          Row(
            children: [
              GestureDetector(
                onTap: widget.onAvatarTap,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: const Color(0xFF00F5D4), width: 2),
                    color: Colors.white10,
                    image: (widget.photoPath != null &&
                        File(widget.photoPath!).existsSync())
                        ? DecorationImage(
                      image: FileImage(File(widget.photoPath!)),
                      fit: BoxFit.cover,
                    )
                        : null,
                  ),
                  child: (widget.photoPath == null ||
                      !File(widget.photoPath!).existsSync())
                      ? const Icon(Icons.add_a_photo_rounded,
                      color: Colors.white70, size: 24)
                      : null,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$gender  ·  DOB: $dob',
                      style:
                      const TextStyle(color: Colors.white70, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ICE: $ice',
                      style: const TextStyle(
                        color: Color(0xFF00F5D4),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Bottom Telemetry & Flip Cue Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.isVaultLocked
                        ? 'Allergies: ${u?.allergies.length ?? 0}  ·  Meds/Cond: 🔒 Vault'
                        : 'Allergies: ${u?.allergies.length ?? 0}  ·  Meds: ${u?.medications.length ?? 0}  ·  Cond: ${u?.conditions.length ?? 0}',
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.threed_rotation,
                        color: Color(0xFF38BDF8), size: 13),
                    SizedBox(width: 4),
                    Text(
                      '3D Flip QR',
                      style: TextStyle(
                        color: Color(0xFF38BDF8),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
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

  Widget _buildBackQrCard(UserModel? u) {
    final qrPayload = u != null
        ? QrService.generatePayload(u)
        : '{"app":"JanRaksha","n":"Unconfigured"}';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF00F5D4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00F5D4).withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: QrImageView(
              data: qrPayload,
              version: QrVersions.auto,
              size: 125,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.offline_bolt,
                        color: Color(0xFF00F5D4), size: 14),
                    SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'OFFLINE RESPONDER QR',
                        style: TextStyle(
                          color: Color(0xFF00F5D4),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Text(
                  'Instant Paramedic Scan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Decodes Blood Group, Allergies & ICE Phone without internet.',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.touch_app, color: Color(0xFF38BDF8), size: 13),
                    SizedBox(width: 4),
                    Text(
                      'Tap Card to Flip Front',
                      style: TextStyle(
                        color: Color(0xFF38BDF8),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
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

// ══════════════════════════════════════════════════════════════════════════
// 4. LIVE ANIMATED ECG WAVEFORM & TELEMETRY CARD
// ══════════════════════════════════════════════════════════════════════════
class _LiveEcgTelemetryCard extends StatelessWidget {
  final UserModel? user;
  final VitalsEntry? latestVital;
  final bool isVaultLocked;
  final Animation<double> ecgAnimation;
  final VoidCallback onTap;

  const _LiveEcgTelemetryCard({
    required this.user,
    required this.latestVital,
    required this.isVaultLocked,
    required this.ecgAnimation,
    required this.onTap,
  });

  int _calculateScore() {
    int score = 65;
    if (user != null) {
      if (user!.bloodGroup.isNotEmpty) score += 10;
      if (user!.emergencyContactPhone.isNotEmpty) score += 10;
    }
    if (latestVital != null) {
      if (latestVital!.alertLevel == 'normal') score += 15;
      if (latestVital!.alertLevel == 'warning') score += 5;
      if (latestVital!.alertLevel == 'danger') score -= 15;
    }
    return score.clamp(25, 100);
  }

  @override
  Widget build(BuildContext context) {
    final score = _calculateScore();
    final Color scoreColor = score >= 80
        ? const Color(0xFF00F5D4)
        : (score >= 60 ? Colors.amberAccent : const Color(0xFFFF416C));

    return _PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF111827).withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
              color: const Color(0xFF38BDF8).withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Readiness Ring
                SizedBox(
                  width: 58,
                  height: 58,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: score / 100,
                        strokeWidth: 5.5,
                        backgroundColor: Colors.white10,
                        valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$score',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: scoreColor,
                            ),
                          ),
                          const Text(
                            'BIO-SCORE',
                            style: TextStyle(
                              fontSize: 6.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),

                // Live Animated ECG Canvas + Header
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Flexible(
                            child: Text(
                              'Live Bio-Telemetry Stream',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            isVaultLocked ? '🔒 Vault' : 'AI Charts →',
                            style: const TextStyle(
                              color: Color(0xFF38BDF8),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 28,
                        width: double.infinity,
                        child: AnimatedBuilder(
                          animation: ecgAnimation,
                          builder: (context, _) => CustomPaint(
                            painter: _EcgWavePainter(
                              phase: ecgAnimation.value,
                              color: scoreColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: Colors.white12, height: 1),
            const SizedBox(height: 10),

            // 3 Telemetry Columns
            Row(
              children: [
                Expanded(
                  child: _DarkVitalMetric(
                    icon: Icons.favorite_rounded,
                    color: const Color(0xFFFF416C),
                    label: 'Heart Rate',
                    value: isVaultLocked
                        ? '••• bpm'
                        : (latestVital != null
                        ? '${latestVital!.heartRate} bpm'
                        : '-- bpm'),
                  ),
                ),
                Expanded(
                  child: _DarkVitalMetric(
                    icon: Icons.speed_rounded,
                    color: const Color(0xFF38BDF8),
                    label: 'Blood Press.',
                    value: isVaultLocked
                        ? '•••/••'
                        : (latestVital != null
                        ? '${latestVital!.systolicBP}/${latestVital!.diastolicBP}'
                        : '--/--'),
                  ),
                ),
                Expanded(
                  child: _DarkVitalMetric(
                    icon: Icons.water_drop_rounded,
                    color: const Color(0xFFA855F7),
                    label: 'Glucose',
                    value: isVaultLocked
                        ? '••• mg/dL'
                        : (latestVital != null
                        ? '${latestVital!.glucoseLevel} mg/dL'
                        : '--'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EcgWavePainter extends CustomPainter {
  final double phase;
  final Color color;

  _EcgWavePainter({required this.phase, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final midY = size.height / 2;

    for (double x = 0; x <= size.width; x += 2) {
      final norm = ((x / size.width) + phase) % 1.0;
      double y = midY;

      // Simulate realistic P-Q-R-S-T heartbeat spike
      if (norm > 0.40 && norm < 0.44) {
        y = midY + 4;
      } else if (norm >= 0.44 && norm < 0.48) {
        y = midY - 12;
      } else if (norm >= 0.48 && norm < 0.52) {
        y = midY + 9;
      } else if (norm >= 0.56 && norm < 0.64) {
        y = midY - 4 * math.sin((norm - 0.56) / 0.08 * math.pi);
      }

      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _EcgWavePainter oldDelegate) =>
      oldDelegate.phase != phase;
}

class _DarkVitalMetric extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _DarkVitalMetric({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(fontSize: 10, color: Colors.white54),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// 5. DYNAMIC MEDICATION CHECKLIST DECK
// ══════════════════════════════════════════════════════════════════════════
class _DynamicMedicationDeck extends StatelessWidget {
  final List<String> medications;
  final Set<String> takenMeds;
  final bool isVaultLocked;
  final ValueChanged<String> onToggle;
  final VoidCallback onUnlockTap;

  const _DynamicMedicationDeck({
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
        color: const Color(0xFF111827).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.medication_liquid_rounded,
                  color: Color(0xFF00F5D4), size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Daily Active Regimen',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                isVaultLocked
                    ? '🔒 Vault Locked'
                    : '${takenMeds.length}/${medications.length} Doses Taken',
                style: const TextStyle(
                  color: Color(0xFF00F5D4),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (isVaultLocked)
            GestureDetector(
              onTap: onUnlockTap,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.face_retouching_natural,
                        color: Color(0xFFF59E0B), size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Medications hidden in Responder Mode. Tap to scan face.',
                        style:
                        TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: medications.map((med) {
                final taken = takenMeds.contains(med);
                return GestureDetector(
                  onTap: () => onToggle(med),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: taken
                          ? const Color(0xFF10B981).withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: taken
                            ? const Color(0xFF10B981)
                            : Colors.white24,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          taken
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked,
                          size: 14,
                          color: taken
                              ? const Color(0xFF00F5D4)
                              : Colors.white54,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          med,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            decoration:
                            taken ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// 6. DYNAMIC PRESSABLE BENTO MATRIX (ALL 8 PHASES + FIRST-AID + ABOUT)
// ══════════════════════════════════════════════════════════════════════════
class _DynamicBentoMatrix extends StatelessWidget {
  final bool isVaultLocked;
  final ValueChanged<String> onNavigateProtected;

  const _DynamicBentoMatrix({
    required this.isVaultLocked,
    required this.onNavigateProtected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Row 1: Two Large Gradient AI Hero Cards
        Row(
          children: [
            Expanded(
              child: _HeroGlowCard(
                title: 'AI Symptom\nTriage',
                subtitle: 'Gemini 3.5 Neural Check',
                badge: 'PHASE 3',
                icon: Icons.psychology_alt_rounded,
                gradient: const [Color(0xFF0284C7), Color(0xFF00B4D8)],
                onTap: () => Navigator.pushNamed(
                    context, AppConstants.symptomCheckerRoute),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _HeroGlowCard(
                title: 'OCR Medical\nDoc Scanner',
                subtitle: isVaultLocked ? '🔒 Vault Locked' : 'ML Kit + AI Parse',
                badge: 'PHASE 4',
                icon: Icons.document_scanner_rounded,
                gradient: const [Color(0xFF0D9488), Color(0xFF10B981)],
                onTap: () => onNavigateProtected(AppConstants.docScannerRoute),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Row 2: Three Neon Glass Modules
        Row(
          children: [
            Expanded(
              child: _GlassModuleTile(
                title: 'Drug Check',
                subtitle: 'Conflict AI',
                icon: Icons.science_rounded,
                accent: const Color(0xFFF59E0B),
                onTap: () =>
                    Navigator.pushNamed(context, AppConstants.drugCheckerRoute),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _GlassModuleTile(
                title: 'Vitals AI',
                subtitle: isVaultLocked ? '🔒 Vault' : 'Live Charts',
                icon: Icons.monitor_heart_rounded,
                accent: const Color(0xFFA855F7),
                onTap: () => onNavigateProtected(AppConstants.vitalsRoute),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _GlassModuleTile(
                title: 'Hospitals',
                subtitle: 'GPS Triage',
                icon: Icons.local_hospital_rounded,
                accent: const Color(0xFF10B981),
                onTap: () => Navigator.pushNamed(
                    context, AppConstants.hospitalFinderRoute),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Row 3: Face Biometric Vault + Responder QR Scanner
        Row(
          children: [
            Expanded(
              child: _WideNeonBanner(
                title: 'Face Biometric Lock',
                subtitle: 'ML Kit Eye Liveness',
                icon: Icons.face_retouching_natural,
                accent: const Color(0xFF6366F1),
                onTap: () =>
                    Navigator.pushNamed(context, AppConstants.faceLockRoute),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _WideNeonBanner(
                title: 'Scan Patient QR',
                subtitle: 'Responder Decoder',
                icon: Icons.qr_code_scanner_rounded,
                accent: const Color(0xFF00F5D4),
                onTap: () =>
                    Navigator.pushNamed(context, AppConstants.scanQrRoute),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Row 4: Offline CPR Metronome + System Architecture
        Row(
          children: [
            Expanded(
              child: _WideNeonBanner(
                title: 'First-Aid & CPR',
                subtitle: '110 BPM Offline Pacer',
                icon: Icons.favorite_border_rounded,
                accent: const Color(0xFFFF416C),
                onTap: () {
                  try {
                    Navigator.pushNamed(context, '/first-aid');
                  } catch (_) {}
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _WideNeonBanner(
                title: 'App Architecture',
                subtitle: '8-Phase Tech Stack',
                icon: Icons.hub_rounded,
                accent: const Color(0xFF38BDF8),
                onTap: () {
                  try {
                    Navigator.pushNamed(context, '/about');
                  } catch (_) {}
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeroGlowCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String badge;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _HeroGlowCard({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 6),
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
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white70, fontSize: 10.5),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassModuleTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  const _GlassModuleTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: const Color(0xFF111827).withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: accent, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white54, fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _WideNeonBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  const _WideNeonBanner({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: const Color(0xFF111827).withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accent.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: accent, size: 19),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

// ══════════════════════════════════════════════════════════════════════════
// 7. DYNAMIC GLASS BOTTOM DOCK WITH LIVE PULSING SOS ORB
// ══════════════════════════════════════════════════════════════════════════
class _DynamicGlassBottomDock extends StatelessWidget {
  final Animation<double> pulseAnimation;
  final bool isVaultLocked;
  final VoidCallback onQrTap;
  final VoidCallback onVitalsTap;
  final VoidCallback onSosTap;
  final VoidCallback onProfileTap;
  final VoidCallback onEditTap;

  const _DynamicGlassBottomDock({
    required this.pulseAnimation,
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
      decoration: BoxDecoration(
        color: const Color(0xFF0B1120).withValues(alpha: 0.96),
        border: const Border(top: BorderSide(color: Colors.white12)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _DockNavBtn(
                icon: Icons.qr_code_2_rounded,
                label: 'QR Pass',
                onTap: onQrTap,
              ),
              _DockNavBtn(
                icon: Icons.monitor_heart_outlined,
                label: isVaultLocked ? 'Vitals 🔒' : 'Vitals',
                onTap: onVitalsTap,
              ),

              // Live Pulsing SOS Orb
              GestureDetector(
                onTap: onSosTap,
                child: AnimatedBuilder(
                  animation: pulseAnimation,
                  builder: (context, child) {
                    final pulse =
                        (math.sin(pulseAnimation.value * 2 * math.pi) + 1) / 2;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 9),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)],
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF416C)
                                .withValues(alpha: 0.35 + (pulse * 0.35)),
                            blurRadius: 10 + (pulse * 8),
                            spreadRadius: pulse * 2,
                          ),
                        ],
                      ),
                      child: child,
                    );
                  },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.mic, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'SOS',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              _DockNavBtn(
                icon: Icons.person_outline_rounded,
                label: isVaultLocked ? 'Profile 🔒' : 'Profile',
                onTap: onProfileTap,
              ),
              _DockNavBtn(
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

class _DockNavBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DockNavBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white70, size: 20),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}