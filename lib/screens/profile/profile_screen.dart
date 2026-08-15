import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../models/user_model.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userModel;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              await Navigator.pushNamed(context, AppConstants.editProfileRoute);
              // Refresh data after returning from edit
              if (context.mounted) {
                context.read<AuthProvider>().refreshUser();
              }
            },
            tooltip: 'Edit Profile',
          ),
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : _Body(user: user),
    );
  }
}

class _Body extends StatelessWidget {
  final UserModel user;
  const _Body({required this.user});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // ── Avatar + Name ─────────────────────────────────
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 46,
                  backgroundColor: AppTheme.primaryColor,
                  child: Text(
                    _initials(user.name),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                Text(user.name,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(user.email,
                    style: Theme.of(context).textTheme.bodyMedium),
                if (user.bloodGroup.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '🩸 ${user.bloodGroup}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ── Completion Banner ─────────────────────────────
          if (_profileCompletion(user) < 100) ...[
            _CompletionBanner(percent: _profileCompletion(user)),
            const SizedBox(height: 20),
          ],

          // ── Basic Info ────────────────────────────────────
          _SectionCard(
            title: 'Basic Information',
            icon: Icons.person_outline,
            children: [
              _Row(label: 'Phone', value: user.phone),
              _Row(label: 'Date of Birth', value: user.dateOfBirth),
              _Row(label: 'Gender', value: user.gender),
            ],
          ),
          const SizedBox(height: 14),

          // ── Medical Info ──────────────────────────────────
          _SectionCard(
            title: 'Medical Information',
            icon: Icons.medical_information_outlined,
            children: [
              _Row(label: 'Blood Group', value: user.bloodGroup, isHighlight: true),
              _TagRow(
                  label: 'Allergies',
                  tags: user.allergies,
                  color: Colors.orange),
              _TagRow(
                  label: 'Medications',
                  tags: user.medications,
                  color: AppTheme.primaryColor),
              _TagRow(
                  label: 'Conditions',
                  tags: user.conditions,
                  color: Colors.purple),
            ],
          ),
          const SizedBox(height: 14),

          // ── Emergency Contact ─────────────────────────────
          _SectionCard(
            title: 'Emergency Contact',
            icon: Icons.emergency_outlined,
            children: [
              _Row(label: 'Name', value: user.emergencyContactName),
              _Row(label: 'Phone', value: user.emergencyContactPhone),
              _Row(label: 'Relation', value: user.emergencyContactRelation),
            ],
          ),
          const SizedBox(height: 24),

          // ── Action Buttons ────────────────────────────────
          ElevatedButton.icon(
            onPressed: () async {
              await Navigator.pushNamed(
                  context, AppConstants.editProfileRoute);
              if (context.mounted) {
                context.read<AuthProvider>().refreshUser();
              }
            },
            icon: const Icon(Icons.edit),
            label: const Text('Edit Profile'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () =>
                Navigator.pushNamed(context, AppConstants.qrRoute),
            icon: const Icon(Icons.qr_code_2),
            label: const Text('View My QR Code'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              side: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _initials(String name) {
    if (name.isEmpty) return 'J';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  int _profileCompletion(UserModel u) {
    int filled = 0;
    const total = 8;
    if (u.phone.isNotEmpty) filled++;
    if (u.bloodGroup.isNotEmpty) filled++;
    if (u.dateOfBirth.isNotEmpty) filled++;
    if (u.gender.isNotEmpty) filled++;
    if (u.allergies.isNotEmpty) filled++;
    if (u.emergencyContactName.isNotEmpty) filled++;
    if (u.emergencyContactPhone.isNotEmpty) filled++;
    if (u.emergencyContactRelation.isNotEmpty) filled++;
    return ((filled / total) * 100).round();
  }
}

// ── Section Card ───────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard(
      {required this.title,
        required this.icon,
        required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06), blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Icon(icon, color: AppTheme.primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppTheme.textPrimary)),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }
}

// ── Info Row ───────────────────────────────────────────────────
class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlight;

  const _Row(
      {required this.label, required this.value, this.isHighlight = false});

  @override
  Widget build(BuildContext context) {
    final isEmpty = value.isEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13)),
          if (isHighlight && !isEmpty)
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.errorColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            )
          else
            Text(
              isEmpty ? 'Not set' : value,
              style: TextStyle(
                  color: isEmpty
                      ? AppTheme.textSecondary
                      : AppTheme.textPrimary,
                  fontSize: 14,
                  fontStyle:
                  isEmpty ? FontStyle.italic : FontStyle.normal,
                  fontWeight: FontWeight.w500),
            ),
        ],
      ),
    );
  }
}

// ── Tag Row ────────────────────────────────────────────────────
class _TagRow extends StatelessWidget {
  final String label;
  final List<String> tags;
  final Color color;

  const _TagRow(
      {required this.label, required this.tags, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13)),
          const SizedBox(height: 6),
          tags.isEmpty
              ? const Text('None',
              style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontStyle: FontStyle.italic,
                  fontSize: 13))
              : Wrap(
            spacing: 6,
            runSpacing: 4,
            children: tags
                .map((t) => Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: color.withValues(alpha: 0.3)),
              ),
              child: Text(t,
                  style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w500)),
            ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ── Completion Banner ──────────────────────────────────────────
class _CompletionBanner extends StatelessWidget {
  final int percent;
  const _CompletionBanner({required this.percent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border:
        Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Profile $percent% complete',
                  style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
              Text('$percent%',
                  style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent / 100,
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
              color: AppTheme.primaryColor,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'A complete profile helps emergency responders help you faster.',
            style:
            TextStyle(color: AppTheme.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }
}