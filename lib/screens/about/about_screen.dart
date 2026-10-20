import 'package:flutter/material.dart';
import '../../core/theme.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  static const List<Map<String, dynamic>> _architecturePhases = [
    {
      'phase': 'Phase 1 & 2',
      'title': 'Cloud Auth & Offline QR Payload',
      'desc': 'Firebase Authentication + high-density JSON QR encoding that works 100% offline for paramedics.',
      'icon': Icons.qr_code_2_rounded,
      'color': Color(0xFF0066CC),
    },
    {
      'phase': 'Phase 3',
      'title': 'Gemini 1.5 Clinical Triage & Drug AI',
      'desc': 'Context-aware symptom severity analysis and multi-drug interaction conflict detection.',
      'icon': Icons.psychology_outlined,
      'color': Color(0xFF00B4D8),
    },
    {
      'phase': 'Phase 4',
      'title': 'On-Device OCR Lab & Rx Scanner',
      'desc': 'Google ML Kit Text Recognition paired with AI structuring to digitize physical prescriptions.',
      'icon': Icons.document_scanner_outlined,
      'color': Color(0xFF0D9488),
    },
    {
      'phase': 'Phase 5',
      'title': 'Real-Time Vitals Telemetry & Charts',
      'desc': 'Firestore subcollection streaming with FL Chart trend visualization and anomaly detection.',
      'icon': Icons.monitor_heart_outlined,
      'color': Colors.purple,
    },
    {
      'phase': 'Phase 6',
      'title': 'Hands-Free Voice SOS & LED Beacon',
      'desc': 'Speech-to-text emergency trigger, hardware camera torch strobe, and GPS SMS dispatch.',
      'icon': Icons.emergency_share_rounded,
      'color': Color(0xFFEF4444),
    },
    {
      'phase': 'Phase 7',
      'title': 'ML Kit Face Liveness Vault',
      'desc': 'Dual-eye open probability & head-euler angle verification to prevent photo spoof attacks.',
      'icon': Icons.face_retouching_natural,
      'color': Colors.indigo,
    },
    {
      'phase': 'Phase 8',
      'title': 'Geolocator Hospital & Triage Finder',
      'desc': 'Live GPS lock with specialty-filtered emergency hospital routing and pre-arrival care advice.',
      'icon': Icons.local_hospital_outlined,
      'color': Color(0xFF10B981),
    },
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('System Architecture & About'),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Hero Brand Banner ─────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0F172A), Color(0xFF004E92)],
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF004E92).withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.cyanAccent.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.health_and_safety_rounded,
                      color: Colors.cyanAccent,
                      size: 42,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'JanRaksha ID',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Next-Gen AI Medical Identity & Emergency Response Platform',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  const Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _TechBadge('Flutter 3.x'),
                      _TechBadge('Firebase Cloud'),
                      _TechBadge('Gemini 1.5 AI'),
                      _TechBadge('Google ML Kit'),
                      _TechBadge('Zero-Cost Offline QR'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Developer & Academic Attribution Card ─────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor:
                    AppTheme.primaryColor.withValues(alpha: 0.12),
                    child: const Icon(
                      Icons.engineering_rounded,
                      color: AppTheme.primaryColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DEVELOPED BY',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                            letterSpacing: 0.8,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Sunny Kakdiya',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Gyanmanjari Innovative University (GMIU)',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── 8-Phase Engineering Pipeline ──────────────────────────
            const Text(
              '8-Phase Engineering Architecture',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 10),

            ...List.generate(_architecturePhases.length, (index) {
              final item = _architecturePhases[index];
              final start = (index * 0.1).clamp(0.0, 0.7);
              final end = (start + 0.3).clamp(0.0, 1.0);
              final animation = CurvedAnimation(
                parent: _animController,
                curve: Interval(start, end, curve: Curves.easeOutCubic),
              );

              return AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  return Opacity(
                    opacity: animation.value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - animation.value)),
                      child: child,
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (item['color'] as Color).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          item['icon'] as IconData,
                          color: item['color'] as Color,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    item['title'] as String,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (item['color'] as Color)
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    item['phase'] as String,
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: item['color'] as Color,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item['desc'] as String,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppTheme.textSecondary,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _TechBadge extends StatelessWidget {
  final String label;
  const _TechBadge(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}