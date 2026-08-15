import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Reusable widget used on all AI screens.
/// Shows loading → result → error states cleanly.
class AiResponseCard extends StatelessWidget {
  final bool isLoading;
  final String? response;
  final String? error;
  final VoidCallback? onRetry;

  const AiResponseCard({
    super.key,
    this.isLoading = false,
    this.response,
    this.error,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) return _LoadingState();
    if (error != null) return _ErrorState(message: error!, onRetry: onRetry);
    if (response != null) return _ResultState(response: response!);
    return const SizedBox.shrink();
  }
}

// ── Loading State ──────────────────────────────────────────────
class _LoadingState extends StatefulWidget {
  @override
  State<_LoadingState> createState() => _LoadingStateState();
}

class _LoadingStateState extends State<_LoadingState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  final _messages = [
    '🧠  Analyzing your medical profile...',
    '🔍  Cross-checking with known data...',
    '⚕️   Preparing response...',
  ];
  int _msgIndex = 0;

  @override
  void initState() {
    super.initState();
    _ctrl =
    AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(_ctrl);

    // Cycle loading messages
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return false;
      setState(() => _msgIndex = (_msgIndex + 1) % _messages.length);
      return true;
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          FadeTransition(
            opacity: _anim,
            child: const Icon(Icons.psychology,
                color: AppTheme.primaryColor, size: 44),
          ),
          const SizedBox(height: 16),
          Text(
            _messages[_msgIndex],
            style: const TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w500,
                fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const LinearProgressIndicator(
            backgroundColor: Color(0xFFE5E7EB),
            color: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }
}

// ── Error State ────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const _ErrorState({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border:
        Border.all(color: AppTheme.errorColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline,
              color: AppTheme.errorColor, size: 36),
          const SizedBox(height: 10),
          const Text('AI request failed',
              style: TextStyle(
                  color: AppTheme.errorColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
          const SizedBox(height: 6),
          Text(
            message.length > 120
                ? '${message.substring(0, 120)}...'
                : message,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Try Again'),
              style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.errorColor,
                  side: const BorderSide(color: AppTheme.errorColor)),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Result State ───────────────────────────────────────────────
class _ResultState extends StatelessWidget {
  final String response;
  const _ResultState({required this.response});

  // Parse SEVERITY line for color
  Color _severityColor(String text) {
    final match =
    RegExp(r'SEVERITY:\s*(\w+)', caseSensitive: false).firstMatch(text);
    final s = match?.group(1)?.toUpperCase() ?? '';
    if (s == 'MILD') return Colors.green;
    if (s == 'MODERATE') return Colors.orange;
    if (s == 'SEVERE') return AppTheme.errorColor;
    if (s == 'EMERGENCY') return Colors.red.shade900;
    if (s == 'MAJOR') return AppTheme.errorColor;
    if (s == 'MINOR') return Colors.orange;
    if (s == 'NONE') return AppTheme.successColor;
    return AppTheme.textSecondary;
  }

  String _severityLabel(String text) {
    final match =
    RegExp(r'SEVERITY:\s*(\w+)', caseSensitive: false).firstMatch(text);
    return match?.group(1) ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final severity = _severityLabel(response);
    final color = _severityColor(response);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.psychology,
                    color: AppTheme.primaryColor, size: 20),
                const SizedBox(width: 8),
                const Text('AI Analysis',
                    style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                const Spacer(),
                if (severity.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      severity.toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),

          // ── Parsed Response Body ─────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: _FormattedResponse(text: response),
          ),

          // ── AI Disclaimer ────────────────────────────────
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFFFF3CD),
              borderRadius:
              BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline,
                    color: Color(0xFFB7791F), size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AI analysis is informational only. Always consult a qualified medical professional.',
                    style: TextStyle(
                        color: Color(0xFF92400E),
                        fontSize: 11),
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

// ── Formatted Response Parser ──────────────────────────────────
class _FormattedResponse extends StatelessWidget {
  final String text;
  const _FormattedResponse({required this.text});

  static const _sectionColors = {
    'SEVERITY': AppTheme.primaryColor,
    'POSSIBLE CAUSES': Colors.orange,
    'IMMEDIATE ACTIONS': AppTheme.successColor,
    'SEEK EMERGENCY CARE': AppTheme.errorColor,
    'IMPORTANT NOTE': Colors.purple,
    'INTERACTIONS FOUND': AppTheme.primaryColor,
    'DETAILS': AppTheme.textPrimary,
    'RECOMMENDATIONS': AppTheme.successColor,
    'DISCLAIMER': AppTheme.textSecondary,
  };

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');
    final widgets = <Widget>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) {
        widgets.add(const SizedBox(height: 8));
        continue;
      }

      // Section header (ALL CAPS with colon)
      final headerMatch =
      RegExp(r'^([A-Z][A-Z\s]+):\s*(.*)$').firstMatch(line);
      if (headerMatch != null) {
        final label = headerMatch.group(1)!.trim();
        final value = headerMatch.group(2)!.trim();
        final color = _sectionColors[label] ?? AppTheme.primaryColor;

        if (value.isNotEmpty) {
          // Inline value (e.g. "SEVERITY: Moderate")
          widgets.add(Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                      text: '$label: ',
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          fontFamily: 'Poppins')),
                  TextSpan(
                      text: value,
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins')),
                ],
              ),
            ),
          ));
        } else {
          // Section title only
          widgets.add(Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 4),
            child: Text(
              label,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
            ),
          ));
        }
        continue;
      }

      // Bullet point
      if (line.startsWith('•') || line.startsWith('-')) {
        final content = line.replaceFirst(RegExp(r'^[•\-]\s*'), '');
        widgets.add(Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('• ',
                  style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
              Expanded(
                  child: Text(content,
                      style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textPrimary))),
            ],
          ),
        ));
        continue;
      }

      // Normal text
      widgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(line,
            style: const TextStyle(
                fontSize: 13, color: AppTheme.textPrimary)),
      ));
    }

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: widgets);
  }
}