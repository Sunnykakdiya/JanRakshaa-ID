import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/loading_button.dart';
import '../../widgets/tag_input_field.dart';

/// Shows the structured data extracted from a scanned document.
/// User can review / edit each field, then import them into the profile.
class ScanExtractResultScreen extends StatefulWidget {
  final String rawText;
  final Map<String, dynamic> structured;
  final String imagePath;

  const ScanExtractResultScreen({
    super.key,
    required this.rawText,
    required this.structured,
    required this.imagePath,
  });

  @override
  State<ScanExtractResultScreen> createState() =>
      _ScanExtractResultScreenState();
}

class _ScanExtractResultScreenState
    extends State<ScanExtractResultScreen> {
  // Editable extracted fields
  late String _bloodGroup;
  late List<String> _medications;
  late List<String> _allergies;
  late List<String> _conditions;

  // Info-only fields (shown but not imported to profile)
  late String _doctorName;
  late String _hospital;
  late String _dateOfReport;
  late String _patientName;

  bool _showRawText = false;
  bool _isSaving = false;
  bool _hasAnyData = false;

  @override
  void initState() {
    super.initState();
    _bloodGroup = widget.structured['blood_group']?.toString() ?? '';
    _medications =
    List<String>.from(widget.structured['medications'] ?? []);
    _allergies =
    List<String>.from(widget.structured['allergies'] ?? []);
    _conditions =
    List<String>.from(widget.structured['conditions'] ?? []);
    _doctorName = widget.structured['doctor_name']?.toString() ?? '';
    _hospital = widget.structured['hospital']?.toString() ?? '';
    _dateOfReport =
        widget.structured['date_of_report']?.toString() ?? '';
    _patientName =
        widget.structured['patient_name']?.toString() ?? '';

    _hasAnyData = _bloodGroup.isNotEmpty ||
        _medications.isNotEmpty ||
        _allergies.isNotEmpty ||
        _conditions.isNotEmpty;
  }

  Future<void> _importToProfile() async {
    final userProvider = context.read<UserProvider>();
    final current = userProvider.user ??
        context.read<AuthProvider>().userModel;
    if (current == null) return;

    setState(() => _isSaving = true);

    // Merge: extracted values override existing only if non-empty
    final updated = current.copyWith(
      bloodGroup: _bloodGroup.isNotEmpty ? _bloodGroup : current.bloodGroup,
      medications: _medications.isNotEmpty
          ? _mergeUnique(current.medications, _medications)
          : current.medications,
      allergies: _allergies.isNotEmpty
          ? _mergeUnique(current.allergies, _allergies)
          : current.allergies,
      conditions: _conditions.isNotEmpty
          ? _mergeUnique(current.conditions, _conditions)
          : current.conditions,
    );

    final success = await userProvider.updateProfile(updated);
    if (success && mounted) {
      context.read<AuthProvider>().updateLocalUser(updated);
    }

    setState(() => _isSaving = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Profile updated with scanned data!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        // Pop back to doc scanner
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save. Please try again.'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  List<String> _mergeUnique(List<String> existing, List<String> incoming) {
    final result = List<String>.from(existing);
    for (final item in incoming) {
      if (!result.any((e) => e.toLowerCase() == item.toLowerCase())) {
        result.add(item);
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Extracted Data'),
        actions: [
          IconButton(
            icon: Icon(_showRawText
                ? Icons.text_fields
                : Icons.raw_on_outlined),
            onPressed: () =>
                setState(() => _showRawText = !_showRawText),
            tooltip: _showRawText ? 'Show Parsed' : 'Show Raw Text',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Document Preview (small) ───────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(widget.imagePath),
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                    height: 140,
                    color: Colors.grey.shade200,
                    child:
                    const Center(child: Icon(Icons.image, size: 40))),
              ),
            ),
            const SizedBox(height: 16),

            // ── No data warning ────────────────────────────────
            if (!_hasAnyData) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'No recognizable medical data was found. The document may not be a standard medical record, or the image quality may be low.',
                        style: TextStyle(
                            color: Colors.orange, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Raw Text Toggle ────────────────────────────────
            if (_showRawText) ...[
              const _SectionHeader(
                  icon: Icons.text_snippet_outlined,
                  title: 'Raw OCR Text',
                  color: Colors.grey),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: SelectableText(
                  widget.rawText.trim().isEmpty
                      ? '(No text detected)'
                      : widget.rawText,
                  style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      height: 1.5,
                      color: AppTheme.textPrimary),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // ── Info-only extracted fields ─────────────────────
            if (_patientName.isNotEmpty ||
                _doctorName.isNotEmpty ||
                _hospital.isNotEmpty ||
                _dateOfReport.isNotEmpty) ...[
              const _SectionHeader(
                  icon: Icons.info_outline,
                  title: 'Document Information',
                  color: Colors.teal),
              const SizedBox(height: 10),
              _InfoCard(children: [
                if (_patientName.isNotEmpty)
                  _InfoRow('Patient', _patientName),
                if (_doctorName.isNotEmpty)
                  _InfoRow('Doctor', _doctorName),
                if (_hospital.isNotEmpty)
                  _InfoRow('Hospital', _hospital),
                if (_dateOfReport.isNotEmpty)
                  _InfoRow('Date', _dateOfReport),
              ]),
              const SizedBox(height: 20),
            ],

            // ── Importable Medical Fields ──────────────────────
            const _SectionHeader(
              icon: Icons.upload_outlined,
              title: 'Medical Data to Import',
              subtitle: 'Review and edit before importing',
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 4),
            const Text(
              'These fields will be merged with your existing profile (not overwritten).',
              style: TextStyle(
                  color: AppTheme.textSecondary, fontSize: 11),
            ),
            const SizedBox(height: 16),

            // Blood Group
            _BloodGroupField(
              value: _bloodGroup,
              onChanged: (v) => setState(() => _bloodGroup = v),
            ),
            const SizedBox(height: 20),

            // Medications
            TagInputField(
              label: '💊 Medications',
              initialTags: _medications,
              hint: 'Add medication...',
              color: AppTheme.primaryColor,
              onChanged: (tags) =>
                  setState(() => _medications = tags),
            ),
            const SizedBox(height: 20),

            // Allergies
            TagInputField(
              label: '⚠️ Allergies',
              initialTags: _allergies,
              hint: 'Add allergy...',
              color: Colors.orange,
              onChanged: (tags) =>
                  setState(() => _allergies = tags),
            ),
            const SizedBox(height: 20),

            // Conditions
            TagInputField(
              label: '🏥 Medical Conditions',
              initialTags: _conditions,
              hint: 'Add condition...',
              color: Colors.purple,
              onChanged: (tags) =>
                  setState(() => _conditions = tags),
            ),

            const SizedBox(height: 32),

            // ── Import Button ─────────────────────────────────
            LoadingButton(
              text: 'Import to My Profile',
              isLoading: _isSaving,
              onPressed: _hasAnyData ||
                  _medications.isNotEmpty ||
                  _allergies.isNotEmpty ||
                  _conditions.isNotEmpty
                  ? _importToProfile
                  : null,
              icon: Icons.cloud_upload_outlined,
            ),

            const SizedBox(height: 12),

            const Center(
              child: Text(
                'Existing profile data will not be deleted.\nExtracted data is merged with your current profile.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppTheme.textSecondary, fontSize: 11),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ── Blood Group Field ──────────────────────────────────────────────────
class _BloodGroupField extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  static const _groups = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];

  const _BloodGroupField(
      {required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('🩸 Blood Group',
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppTheme.textPrimary)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // Clear selection option
            GestureDetector(
              onTap: () => onChanged(''),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: value.isEmpty
                      ? Colors.grey.shade200
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: value.isEmpty
                          ? Colors.grey
                          : Colors.grey.shade300),
                ),
                child: const Text('None',
                    style: TextStyle(fontSize: 13)),
              ),
            ),
            ..._groups.map((bg) => GestureDetector(
              onTap: () => onChanged(bg),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: value == bg
                      ? AppTheme.errorColor
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: value == bg
                          ? AppTheme.errorColor
                          : Colors.grey.shade300),
                ),
                child: Text(bg,
                    style: TextStyle(
                        color: value == bg
                            ? Colors.white
                            : AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ),
            )),
          ],
        ),
      ],
    );
  }
}

// ── Section Header ─────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: color)),
            if (subtitle != null)
              Text(subtitle!,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 11)),
          ],
        ),
      ],
    );
  }
}

// ── Info Card ──────────────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    color: AppTheme.textPrimary)),
          ),
        ],
      ),
    );
  }
}
