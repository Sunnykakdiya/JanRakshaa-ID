import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authUser = context.watch<AuthProvider>().userModel;
    final liveUser = context.watch<UserProvider>().user;
    final user = liveUser ?? authUser;
    final firstName = (user?.name ?? '').split(' ').first;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () =>
                Navigator.pushNamed(context, AppConstants.profileRoute),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogout(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Greeting ──────────────────────────────────
              Text(
                firstName.isEmpty ? 'Hi there 👋' : 'Hi, $firstName 👋',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              Text('Your emergency profile is active.',
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 20),

              // ── Profile incomplete banner ──────────────────
              if (user != null && user.bloodGroup.isEmpty) ...[
                _ProfileBanner(
                  onTap: () => Navigator.pushNamed(
                      context, AppConstants.editProfileRoute),
                ),
                const SizedBox(height: 16),
              ],

              // ── SOS Card ──────────────────────────────────
              _SOSCard(),
              const SizedBox(height: 24),

              // ── Core Actions ──────────────────────────────
              Text('Quick Actions',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 14),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.15,
                children: [
                  _Tile(
                    icon: Icons.qr_code_2,
                    label: 'My QR Code',
                    color: AppTheme.primaryColor,
                    onTap: () =>
                        Navigator.pushNamed(context, AppConstants.qrRoute),
                  ),
                  _Tile(
                    icon: Icons.qr_code_scanner,
                    label: 'Scan QR',
                    color: AppTheme.secondaryColor,
                    onTap: () => Navigator.pushNamed(
                        context, AppConstants.scanQrRoute),
                  ),
                  _Tile(
                    icon: Icons.edit_note,
                    label: 'Edit Profile',
                    color: AppTheme.successColor,
                    onTap: () => Navigator.pushNamed(
                        context, AppConstants.editProfileRoute),
                  ),
                  _Tile(
                    icon: Icons.badge_outlined,
                    label: 'My Profile',
                    color: AppTheme.textSecondary,
                    onTap: () => Navigator.pushNamed(
                        context, AppConstants.profileRoute),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ── Phase 3: AI Features (now active!) ────────
              Row(
                children: [
                  Text('AI Features',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('NEW',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              _AITile(
                icon: Icons.psychology_alt,
                label: 'AI Symptom Checker',
                subtitle: 'Analyze symptoms with your medical context',
                color: AppTheme.primaryColor,
                onTap: () => Navigator.pushNamed(
                    context, AppConstants.symptomCheckerRoute),
              ),
              const SizedBox(height: 10),
              _AITile(
                icon: Icons.medication,
                label: 'Drug Interaction Checker',
                subtitle: 'Check if your medications interact',
                color: Colors.purple,
                onTap: () => Navigator.pushNamed(
                    context, AppConstants.drugCheckerRoute),
              ),

              const SizedBox(height: 24),

              // ── Coming in Later Phases ─────────────────────
              Text('Coming Soon',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 14),
              const _LockedTile(
                  icon: Icons.document_scanner_outlined,
                  label: 'Doc Scanner (OCR)',
                  phase: 'Phase 4'),
              const _LockedTile(
                  icon: Icons.monitor_heart_outlined,
                  label: 'Vitals Tracker',
                  phase: 'Phase 5'),
              const _LockedTile(
                  icon: Icons.mic_outlined,
                  label: 'Voice SOS',
                  phase: 'Phase 6'),
              const _LockedTile(
                  icon: Icons.face_outlined,
                  label: 'Face Biometric Lock',
                  phase: 'Phase 7'),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure?'),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthProvider>().signOut();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

// ── SOS Card ──────────────────────────────────────────────────
class _SOSCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accentColor,
            AppTheme.accentColor.withValues(alpha: 0.8)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentColor.withValues(alpha: 0.3),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.sos, color: Colors.white, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Emergency SOS',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                Text('Voice SOS arrives in Phase 6',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12)),
              ],
            ),
          ),
          Icon(Icons.chevron_right,
              color: Colors.white.withValues(alpha: 0.7)),
        ],
      ),
    );
  }
}

// ── Profile Banner ─────────────────────────────────────────────
class _ProfileBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _ProfileBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.edit_note, color: Colors.orange),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Complete your profile for a useful QR code.',
              style: TextStyle(color: Colors.orange, fontSize: 13),
            ),
          ),
          TextButton(
              onPressed: onTap,
              child: const Text('Fill Now',
                  style: TextStyle(color: Colors.orange))),
        ],
      ),
    );
  }
}

// ── Feature Tile ───────────────────────────────────────────────
class _Tile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _Tile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 10),
            Text(label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ── AI Feature Tile ────────────────────────────────────────────
class _AITile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _AITile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 14, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}

// ── Locked Tile ───────────────────────────────────────────────
class _LockedTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String phase;

  const _LockedTile({
    required this.icon,
    required this.label,
    required this.phase,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.55,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.03), blurRadius: 6)
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.textSecondary, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.textSecondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(phase,
                  style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.lock_outline,
                size: 16, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}