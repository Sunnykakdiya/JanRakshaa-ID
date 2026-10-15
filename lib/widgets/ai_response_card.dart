import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Displays a Gemini AI response with branded styling.
/// Parses sections (POSSIBLE CAUSES:, IMMEDIATE ACTIONS:, etc.)
/// and renders them with colored headings and bullet points.
class AiResponseCard extends StatelessWidget {
  final String response;
  final String? title;

  const AiResponseCard({
    super.key,
    required this.response,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    final sections = _parseSections(response);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.psychology,
                      color: AppTheme.primaryColor, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title ?? 'AI Analysis',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                            fontSize: 14),
                      ),
                      const Text(
                        'Powered by Google Gemini',
                        style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 10),
                      ),
                    ],
                  ),
                ),
                // Emergency level badge (auto-detected)
                _EmergencyBadge(text: response),
              ],
            ),
          ),

          // ── Content ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: sections.isEmpty
                ? Text(response,
                style: const TextStyle(
                    fontSize: 14, height: 1.6,
                    color: AppTheme.textPrimary))
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: sections
                  .map((s) => _SectionBlock(section: s))
                  .toList(),
            ),
          ),

          // ── Footer ─────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16)),
            ),
            child: const Text(
              '⚠️ Not a medical diagnosis. Consult a qualified doctor.',
              style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  List<_Section> _parseSections(String text) {
    final lines = text.split('\n');
    final sections = <_Section>[];
    _Section? current;

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      // Skip disclaimer — already shown in footer
      if (trimmed.startsWith('⚠️ This is not a medical diagnosis')) {
        continue;
      }

      // Detect heading (ends with ':' or is all caps with colon)
      final isHeading = trimmed.endsWith(':') &&
          (trimmed == trimmed.toUpperCase() ||
              RegExp(r'^[A-Z][A-Z\s]+:$').hasMatch(trimmed) ||
              RegExp(r'^(POSSIBLE|IMMEDIATE|EMERGENCY|WHEN|OVERALL|INTERACTIONS|RECOMMENDATIONS|SPECIFIC)').hasMatch(trimmed));

      if (isHeading) {
        if (current != null) sections.add(current);
        current = _Section(
            heading: trimmed.replaceAll(':', ''), lines: []);
      } else {
        current ??= _Section(heading: '', lines: []);
        current.lines.add(trimmed);
      }
    }
    if (current != null) sections.add(current);
    return sections.where((s) => s.lines.isNotEmpty).toList();
  }
}

class _Section {
  final String heading;
  final List<String> lines;
  _Section({required this.heading, required this.lines});
}

class _SectionBlock extends StatelessWidget {
  final _Section section;
  const _SectionBlock({required this.section});

  Color get _headingColor {
    final h = section.heading.toUpperCase();
    if (h.contains('EMERGENCY') || h.contains('RISK')) {
      return AppTheme.errorColor;
    }
    if (h.contains('IMMEDIATE') || h.contains('WHEN')) {
      return Colors.orange.shade700;
    }
    if (h.contains('RECOMMENDATION')) return AppTheme.successColor;
    return AppTheme.primaryColor;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (section.heading.isNotEmpty) ...[
            Text(
              section.heading,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: _headingColor,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 6),
          ],
          ...section.lines.map((line) => _Line(text: line)),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final String text;
  const _Line({required this.text});

  bool get _isBullet =>
      text.startsWith('•') || text.startsWith('-') || text.startsWith('*');

  @override
  Widget build(BuildContext context) {
    // Emergency level line
    if (text.contains('🚨') || text.contains('⚠️') || text.contains('✅')) {
      Color bgColor = AppTheme.successColor.withValues(alpha: 0.1);
      Color textColor = AppTheme.successColor;
      if (text.contains('🚨')) {
        bgColor = AppTheme.errorColor.withValues(alpha: 0.1);
        textColor = AppTheme.errorColor;
      } else if (text.contains('⚠️')) {
        bgColor = Colors.orange.withValues(alpha: 0.1);
        textColor = Colors.orange.shade700;
      }
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: textColor.withValues(alpha: 0.3)),
        ),
        child: Text(
          text,
          style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 13),
        ),
      );
    }

    if (_isBullet) {
      final content =
      text.replaceFirst(RegExp(r'^[•\-\*]\s*'), '').trim();
      return Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Icon(Icons.circle,
                  size: 6, color: AppTheme.primaryColor),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                content,
                style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: AppTheme.textPrimary),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: const TextStyle(
            fontSize: 13, height: 1.5, color: AppTheme.textPrimary),
      ),
    );
  }
}

// ── Emergency Badge (auto-detected from response text) ─────────────
class _EmergencyBadge extends StatelessWidget {
  final String text;
  const _EmergencyBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    if (text.contains('SEEK EMERGENCY CARE NOW')) {
      return _badge('🚨 EMERGENCY', AppTheme.errorColor);
    } else if (text.contains('SEE A DOCTOR TODAY')) {
      return _badge('⚠️ SEE DOCTOR', Colors.orange);
    } else if (text.contains('MONITOR AT HOME')) {
      return _badge('✅ MONITOR', AppTheme.successColor);
    } else if (text.contains('HIGH')) {
      return _badge('HIGH RISK', AppTheme.errorColor);
    } else if (text.contains('MODERATE')) {
      return _badge('MODERATE RISK', Colors.orange);
    }
    return const SizedBox.shrink();
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
