import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/user_model.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user ??
        context.watch<AuthProvider>().userModel;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          _AppHeader(user: user),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── SOS Card ──────────────────────────────────
                _SOSCard(),
                const SizedBox(height: 16),

                // ── Profile incomplete banner ──────────────────
                if (user != null && user.bloodGroup.isEmpty)
                  _ProfileBanner(user: user),

                // ── Quick health chips ─────────────────────────
                if (user != null && user.bloodGroup.isNotEmpty) ...[
                  _HealthChips(user: user),
                  const SizedBox(height: 20),
                ],

                // ── Core Features Grid ─────────────────────────
                const _SectionTitle('Core Features'),
                const SizedBox(height: 12),
                _CoreGrid(),
                const SizedBox(height: 24),

                // ── AI Features (P3+P4 unlocked) ──────────────
                const _SectionTitle('AI Features'),
                const SizedBox(height: 12),
                _AIFeatureList(),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── App Bar ────────────────────────────────────────────────────────────
class _AppHeader extends StatelessWidget {
  final UserModel? user;
  const _AppHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 170,
      floating: false,
      pinned: true,
      automaticallyImplyLeading: false,
      backgroundColor: AppTheme.primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      // Avatar → profile
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(
                            context, AppConstants.profileRoute),
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor:
                          Colors.white.withValues(alpha: 0.25),
                          child: Text(
                            _initials(user),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello, ${_firstName(user)} 👋',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold),
                            ),
                            Row(
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF4ADE80),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  user?.bloodGroup.isNotEmpty == true
                                      ? 'Blood: ${user!.bloodGroup}  ·  ID Active'
                                      : 'Medical ID Active',
                                  style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // ── Gemini Settings icon ──────────────
                      IconButton(
                        icon: const Icon(Icons.psychology,
                            color: Colors.white),
                        onPressed: () => Navigator.pushNamed(
                            context,
                            AppConstants.geminiSettingsRoute),
                        tooltip: 'Gemini AI Settings',
                      ),
                      // ── Logout icon ───────────────────────
                      IconButton(
                        icon: const Icon(Icons.logout,
                            color: Colors.white),
                        onPressed: () =>
                            _showLogoutDialog(context),
                        tooltip: 'Sign Out',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _initials(UserModel? u) {
    if (u == null || u.name.isEmpty) return 'J';
    final parts = u.name.trim().split(' ');
    return parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : parts[0][0].toUpperCase();
  }

  String _firstName(UserModel? u) =>
      u?.name.split(' ').first ?? 'User';

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () =>
            Navigator.pushNamed(context, AppConstants.sosRoute),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.accentColor,
              minimumSize: const Size(60, 36),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
            ),
            child: const Text('SOS',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),

        ],
      ),
    );
  }
}

// ── SOS Card ───────────────────────────────────────────────────────────
class _SOSCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentColor.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.emergency, color: Colors.white, size: 40),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Emergency SOS',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                Text('Phase 6 — Voice-activated alert',
                    style: TextStyle(
                        color: Colors.white60, fontSize: 11)),
              ],
            ),
          ),
      ElevatedButton(
        onPressed: () =>
            Navigator.pushNamed(context, AppConstants.sosRoute), // <-- Add navigation here
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppTheme.accentColor,
          minimumSize: const Size(60, 36),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18)),
        ),
        child: const Text('SOS',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),

        ],
      ),
    );
  }
}

// ── Profile Banner ─────────────────────────────────────────────────────
class _ProfileBanner extends StatelessWidget {
  final UserModel user;
  const _ProfileBanner({required this.user});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: AppTheme.primaryColor.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            const Icon(Icons.edit_note,
                color: AppTheme.primaryColor, size: 22),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Complete your profile to make your QR ID useful.',
                style: TextStyle(
                    color: AppTheme.primaryColor, fontSize: 13),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(
                  context, AppConstants.editProfileRoute),
              child: const Text('Fill Now'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Health Chips ───────────────────────────────────────────────────────
class _HealthChips extends StatelessWidget {
  final UserModel user;
  const _HealthChips({required this.user});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        if (user.bloodGroup.isNotEmpty)
          _Chip(Icons.bloodtype, user.bloodGroup, AppTheme.errorColor),
        if (user.allergies.isNotEmpty)
          _Chip(Icons.warning_amber,
              '${user.allergies.length} Allerg.', Colors.orange),
        if (user.medications.isNotEmpty)
          _Chip(Icons.medication,
              '${user.medications.length} Meds', AppTheme.primaryColor),
        if (user.conditions.isNotEmpty)
          _Chip(Icons.monitor_heart,
              '${user.conditions.length} Cond.', Colors.purple),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Chip(this.icon, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Section Title ──────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.titleLarge);
  }
}

// ── Core Features 2x2 Grid ─────────────────────────────────────────────
class _CoreGrid extends StatelessWidget {
  static const _features = [
    _GridItem(Icons.qr_code_2, 'My QR ID',
        AppTheme.primaryColor, AppConstants.qrRoute),
    _GridItem(Icons.qr_code_scanner, 'Scan QR',
        AppTheme.secondaryColor, AppConstants.scanQrRoute),
    _GridItem(Icons.person_outline, 'My Profile',
        AppTheme.successColor, AppConstants.profileRoute),
    _GridItem(Icons.edit_note, 'Edit Profile',
        Colors.indigo, AppConstants.editProfileRoute),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.3,
      ),
      itemCount: _features.length,
      itemBuilder: (_, i) {
        final f = _features[i];
        return _CoreCard(
          icon: f.icon,
          label: f.label,
          color: f.color,
          onTap: () => Navigator.pushNamed(context, f.route),
        );
      },
    );
  }
}

class _GridItem {
  final IconData icon;
  final String label;
  final Color color;
  final String route;
  const _GridItem(this.icon, this.label, this.color, this.route);
}

class _CoreCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _CoreCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

// ── AI Features List ───────────────────────────────────────────────────
// P3 = unlocked  |  P4 = unlocked  |  P5+ = locked
class _AIFeatureList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = <_AIItem>[
      // ── Phase 3 UNLOCKED ──────────────────────────────────
      const _AIItem(
        icon: Icons.psychology,
        title: 'Symptom Checker',
        subtitle: 'AI-powered symptom analysis',
        phase: 'Phase 3',
        color: AppTheme.primaryColor,
        route: AppConstants.symptomCheckerRoute,
        unlocked: true,
      ),
      const _AIItem(
        icon: Icons.science_outlined,
        title: 'Drug Interaction Check',
        subtitle: 'Check medication interactions',
        phase: 'Phase 3',
        color: Colors.orange,
        route: AppConstants.drugCheckerRoute,
        unlocked: true,
      ),
      // ── Phase 4 UNLOCKED ──────────────────────────────────
      const _AIItem(
        icon: Icons.document_scanner_outlined,
        title: 'Document Scanner',
        subtitle: 'OCR + AI data extraction',
        phase: 'Phase 4',
        color: Colors.teal,
        route: AppConstants.docScannerRoute,
        unlocked: true,
      ),

      // ── Phase 5 UNLOCKED ──────────────────────────────────
        const _AIItem(
        icon: Icons.monitor_heart_outlined,
        title: 'Vitals AI Tracker',
        subtitle: 'Track & detect anomalies',
        phase: 'Phase 5',
        color: Colors.purple,
        route: AppConstants.vitalsRoute,
        unlocked: true, // <-- Changed from false to true
      ),
    // ── Phase 6 UNLOCKED ──────────────────────────────────
        const _AIItem(
          icon: Icons.mic_outlined,
        title: 'Voice SOS',
        subtitle: 'Hands-free emergency alert',
        phase: 'Phase 6',
        color: AppTheme.accentColor,
       route: AppConstants.sosRoute,
       unlocked: true, // <-- Make sure this is set to true
        ),

      const _AIItem(
        icon: Icons.face_outlined,
        title: 'Face Biometric Lock',
        subtitle: 'ML Kit liveness detection',
        phase: 'Phase 7',
        color: Colors.indigo,
        route: '/',
        unlocked: false,
      ),
      const _AIItem(
        icon: Icons.local_hospital_outlined,
        title: 'Hospital Finder',
        subtitle: 'Nearest emergency facility',
        phase: 'Phase 8',
        color: AppTheme.successColor,
        route: '/',
        unlocked: false,
      ),
    ];

    return Column(
      children: items
          .map((item) => _AITile(item: item))
          .toList(),
    );
  }
}

class _AIItem {
  final IconData icon;
  final String title, subtitle, phase, route;
  final Color color;
  final bool unlocked;

  const _AIItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.phase,
    required this.color,
    required this.route,
    required this.unlocked,
  });
}

class _AITile extends StatelessWidget {
  final _AIItem item;
  const _AITile({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: item.unlocked
          ? () => Navigator.pushNamed(context, item.route)
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: item.unlocked
              ? Colors.white
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: item.unlocked
              ? Border.all(color: item.color.withValues(alpha: 0.2))
              : null,
          boxShadow: item.unlocked
              ? [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ]
              : null,
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: item.unlocked
                    ? item.color.withValues(alpha: 0.12)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                item.icon,
                color: item.unlocked ? item.color : Colors.grey,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: item.unlocked
                            ? AppTheme.textPrimary
                            : Colors.grey),
                  ),
                  Text(
                    item.subtitle,
                    style: TextStyle(
                        color: item.unlocked
                            ? AppTheme.textSecondary
                            : Colors.grey.shade400,
                        fontSize: 12),
                  ),
                ],
              ),
            ),
            // Badge + arrow
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: item.unlocked
                        ? item.color.withValues(alpha: 0.12)
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item.phase,
                    style: TextStyle(
                        color: item.unlocked
                            ? item.color
                            : Colors.grey,
                        fontSize: 10,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 4),
                Icon(
                  item.unlocked
                      ? Icons.arrow_forward_ios
                      : Icons.lock_outline,
                  size: 12,
                  color: item.unlocked
                      ? item.color
                      : Colors.grey.shade400,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
