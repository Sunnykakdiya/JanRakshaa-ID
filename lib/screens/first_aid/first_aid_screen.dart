import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme.dart';

class FirstAidScreen extends StatefulWidget {
  const FirstAidScreen({super.key});

  @override
  State<FirstAidScreen> createState() => _FirstAidScreenState();
}

class _FirstAidScreenState extends State<FirstAidScreen> {
  Timer? _cprTimer;
  bool _isCprActive = false;
  bool _beatPulse = false;
  int _compressionCount = 0;

  // 110 BPM = 1 beat every ~545 milliseconds (AHA Clinical Standard)
  void _toggleCprMetronome() {
    if (_isCprActive) {
      _cprTimer?.cancel();
      setState(() {
        _isCprActive = false;
        _beatPulse = false;
        _compressionCount = 0;
      });
    } else {
      setState(() {
        _isCprActive = true;
        _compressionCount = 0;
      });
      _cprTimer =
          Timer.periodic(const Duration(milliseconds: 545), (timer) {
            HapticFeedback.mediumImpact();
            if (mounted) {
              setState(() {
                _beatPulse = !_beatPulse;
                _compressionCount++;
              });
            }
          });
    }
  }

  @override
  void dispose() {
    _cprTimer?.cancel();
    super.dispose();
  }

  static const List<Map<String, dynamic>> _protocols = [
    {
      'title': 'Cardiac Arrest / Unresponsive (CPR)',
      'tag': 'CRITICAL · 110 BPM',
      'color': Color(0xFFEF4444),
      'icon': Icons.favorite_rounded,
      'steps': [
        '1. Check responsiveness and breathing. Call 108 immediately.',
        '2. Place heel of one hand on the center of the chest, interlock fingers.',
        '3. Push hard and fast (2 inches deep) at 100–120 compressions/min (use the CPR Pacer above).',
        '4. Allow complete chest recoil between compressions. Do not stop until paramedics arrive.',
      ],
    },
    {
      'title': 'Severe Arterial Bleeding',
      'tag': 'TRAUMA',
      'color': Colors.deepOrange,
      'icon': Icons.bloodtype_rounded,
      'steps': [
        '1. Apply firm, direct pressure over the wound using a clean cloth or gauze.',
        '2. Elevate the injured limb above the level of the heart if no fracture is suspected.',
        '3. If blood soaks through, do NOT remove the first cloth—add another layer on top.',
        '4. Keep the patient warm and lying flat to prevent hypovolemic shock.',
      ],
    },
    {
      'title': 'Choking (Heimlich Maneuver)',
      'tag': 'AIRWAY',
      'color': Color(0xFF0066CC),
      'icon': Icons.air_rounded,
      'steps': [
        '1. Stand behind the person and wrap your arms around their waist.',
        '2. Make a fist and place it just above their navel (belly button).',
        '3. Grasp your fist with your other hand and perform quick upward & inward abdominal thrusts.',
        '4. Repeat until the object is expelled or the person can breathe/cough.',
      ],
    },
    {
      'title': 'Anaphylaxis / Severe Allergic Shock',
      'tag': 'ALLERGY',
      'color': Colors.purple,
      'icon': Icons.warning_amber_rounded,
      'steps': [
        '1. Check the patient’s JanRaksha QR ID for known allergens.',
        '2. If an Epinephrine Auto-Injector (EpiPen) is available, inject into the outer mid-thigh.',
        '3. Lay the person flat and elevate their legs (unless they are having trouble breathing).',
        '4. Monitor airway and prepare for CPR if breathing stops.',
      ],
    },
    {
      'title': 'Stroke (F.A.S.T. Protocol)',
      'tag': 'NEUROLOGY',
      'color': Color(0xFF0D9488),
      'icon': Icons.psychology_rounded,
      'steps': [
        '1. FACE: Ask the person to smile. Does one side of the face droop?',
        '2. ARMS: Ask them to raise both arms. Does one arm drift downward?',
        '3. SPEECH: Ask them to repeat a simple phrase. Is speech slurred?',
        '4. TIME: Note the exact time symptoms started and rush to a Stroke-Ready Hospital.',
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('Offline First-Aid & CPR Pacer'),
        backgroundColor: AppTheme.errorColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Interactive 110 BPM CPR Compression Pacer ─────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _isCprActive
                    ? (_beatPulse
                    ? const Color(0xFFDC2626)
                    : const Color(0xFF991B1B))
                    : const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (_isCprActive ? AppTheme.errorColor : Colors.black)
                        .withValues(alpha: 0.25),
                    blurRadius: _beatPulse ? 20 : 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      AnimatedScale(
                        scale: _beatPulse ? 1.25 : 1.0,
                        duration: const Duration(milliseconds: 180),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.favorite,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Interactive CPR Metronome (110 BPM)',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _isCprActive
                                  ? 'COMPRESS NOW! Count: $_compressionCount  (30:2 Ratio)'
                                  : 'Visual & haptic pulse guide for chest compressions',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _toggleCprMetronome,
                      icon: Icon(
                          _isCprActive ? Icons.stop_circle : Icons.play_circle),
                      label: Text(
                        _isCprActive
                            ? 'STOP CPR PACER'
                            : 'START 110 BPM CPR PACER',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: _isCprActive
                            ? AppTheme.errorColor
                            : const Color(0xFF0F172A),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Offline Emergency Life-Support Protocols',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 10),

            // ── Expandable First-Aid Flashcards ───────────────────────
            ..._protocols.map((p) {
              final Color color = p['color'] as Color;
              final List<String> steps = p['steps'] as List<String>;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: ExpansionTile(
                  shape: const Border(),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(p['icon'] as IconData, color: color, size: 20),
                  ),
                  title: Text(
                    p['title'] as String,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    p['tag'] as String,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  childrenPadding:
                  const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  children: steps
                      .map(
                        (s) => Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.check_circle_outline,
                              size: 15, color: color),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              s,
                              style: const TextStyle(
                                  fontSize: 12.5, height: 1.35),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                      .toList(),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}