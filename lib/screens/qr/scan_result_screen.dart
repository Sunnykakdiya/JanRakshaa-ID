import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';

/// Shown after scanning a valid JanRaksha QR.
/// Designed for emergency responders to read at a glance.
class ScanResultScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  const ScanResultScreen({super.key, required this.data});

  String get _name => data['name'] as String;
  String get _bg => data['bloodGroup'] as String;
  List<String> get _allergies => data['allergies'] as List<String>;
  List<String> get _medications => data['medications'] as List<String>;
  List<String> get _conditions => data['conditions'] as List<String>;
  String get _ecName => data['emergencyContactName'] as String;
  String get _ecPhone => data['emergencyContactPhone'] as String;
  String get _ecRelation => data['emergencyContactRelation'] as String;
  String get _dob => data['dateOfBirth'] as String;
  String get _gender => data['gender'] as String;

  Future<void> _call(String phone) async {
    if (phone.trim().isEmpty) {
      return;
    }

    final uri = Uri(
      scheme: 'tel',
      path: phone.trim(),
    );

    try {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint('Could not launch phone app: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.errorColor,
        foregroundColor: Colors.white,
        title: const Text('⚠️ Emergency Medical Info'),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── Patient Identity ───────────────────────────
            _IdentityCard(
              name: _name,
              bloodGroup: _bg,
              dob: _dob,
              gender: _gender,
            ),
            const SizedBox(height: 16),

            // ── Allergies (most critical!) ─────────────────
            if (_allergies.isNotEmpty) ...[
              _AlertSection(
                icon: Icons.warning_amber_rounded,
                title: 'ALLERGIES — Do Not Administer',
                items: _allergies,
                color: Colors.orange,
                isAlert: true,
              ),
              const SizedBox(height: 12),
            ],

            // ── Current Medications ────────────────────────
            _InfoSection(
              icon: Icons.medication_outlined,
              title: 'Current Medications',
              items: _medications,
              emptyText: 'None reported',
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 12),

            // ── Medical Conditions ─────────────────────────
            _InfoSection(
              icon: Icons.favorite_border,
              title: 'Medical Conditions',
              items: _conditions,
              emptyText: 'None reported',
              color: Colors.purple,
            ),
            const SizedBox(height: 16),

            // ── Emergency Contact ──────────────────────────
            if (_ecName.isNotEmpty || _ecPhone.isNotEmpty)
              _EmergencyContactCard(
                name: _ecName,
                phone: _ecPhone,
                relation: _ecRelation,
                onCall: () => _call(_ecPhone),
              ),

            const SizedBox(height: 20),

            // ── Disclaimer ─────────────────────────────────
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'This data was provided by the individual. Verify with medical records when possible.',
                style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── Patient Identity Card ──────────────────────────────────────
class _IdentityCard extends StatelessWidget {
  final String name, bloodGroup, dob, gender;
  const _IdentityCard({
    required this.name,
    required this.bloodGroup,
    required this.dob,
    required this.gender,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.errorColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.person, color: Colors.white, size: 42),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? 'Unknown Patient' : name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
                if (dob.isNotEmpty || gender.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    [if (dob.isNotEmpty) 'DOB: $dob', if (gender.isNotEmpty) gender]
                        .join('  ·  '),
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          if (bloodGroup.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text('🩸',
                      style: TextStyle(fontSize: 16)),
                  Text(
                    bloodGroup,
                    style: const TextStyle(
                        color: AppTheme.errorColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Alert Section (for allergies) ─────────────────────────────
class _AlertSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> items;
  final Color color;
  final bool isAlert;

  const _AlertSection({
    required this.icon,
    required this.title,
    required this.items,
    required this.color,
    this.isAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(title,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: items
                  .map((item) => Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(item,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info Section (for medications, conditions) ─────────────────
class _InfoSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> items;
  final String emptyText;
  final Color color;

  const _InfoSection({
    required this.icon,
    required this.title,
    required this.items,
    required this.emptyText,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(title,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: items.isEmpty
                ? Text(emptyText,
                style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontStyle: FontStyle.italic,
                    fontSize: 13))
                : Column(
              children: items
                  .map((item) => Padding(
                padding:
                const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Icon(Icons.circle,
                        color: color, size: 7),
                    const SizedBox(width: 10),
                    Text(item,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Emergency Contact Card ─────────────────────────────────────
class _EmergencyContactCard extends StatelessWidget {
  final String name, phone, relation;
  final VoidCallback onCall;

  const _EmergencyContactCard({
    required this.name,
    required this.phone,
    required this.relation,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.successColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppTheme.successColor.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.emergency_outlined,
                color: AppTheme.successColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Emergency Contact',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 11)),
                Text(
                  name.isEmpty ? 'Not specified' : name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                if (relation.isNotEmpty)
                  Text(relation,
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12)),
                if (phone.isNotEmpty)
                  Text(phone,
                      style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          if (phone.isNotEmpty)
            GestureDetector(
              onTap: onCall,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.successColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.call,
                    color: Colors.white, size: 24),
              ),
            ),
        ],
      ),
    );
  }
}