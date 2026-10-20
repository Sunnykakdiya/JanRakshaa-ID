import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sos_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/sos_service.dart';

class VoiceSosScreen extends StatefulWidget {
  const VoiceSosScreen({super.key});

  @override
  State<VoiceSosScreen> createState() => _VoiceSosScreenState();
}

class _VoiceSosScreenState extends State<VoiceSosScreen> {
  static const MethodChannel _smsChannel =
      MethodChannel('janraksha/direct_sms');

  final MobileScannerController _torchController = MobileScannerController(
    autoStart: false,
  );
  Timer? _strobeTimer;
  bool _isStrobeActive = false;
  bool _screenFlashRed = false;
  bool _hasAutoDispatched = false;
  String _autoDispatchStatus = '';

  static const List<String> _triggerKeywords = [
    '"Help"',
    '"SOS"',
    '"Emergency"',
    '"Ambulance"',
    '"Save me"',
    '"Pain"',
  ];

  void _startStrobeAutomatically() {
    if (_isStrobeActive) return;
    _torchController.start();
    setState(() => _isStrobeActive = true);
    _strobeTimer =
        Timer.periodic(const Duration(milliseconds: 450), (timer) async {
      try {
        await _torchController.toggleTorch();
      } catch (_) {}
      HapticFeedback.heavyImpact();
      if (mounted) {
        setState(() => _screenFlashRed = !_screenFlashRed);
      }
    });
  }

void _stopStrobe() {
_strobeTimer?.cancel();
_torchController.stop();
if (mounted) {
setState(() {
_isStrobeActive = false;
_screenFlashRed = false;
});
}
}

  void _toggleEmergencyStrobe() {
    if (_isStrobeActive) {
      _stopStrobe();
    } else {
      _startStrobeAutomatically();
    }
  }

  /// Automatically sends SMS without touching the screen when SOS triggers
  Future<void> _autoSendEmergencySms(UserModel? user, String message) async {
    if (_hasAutoDispatched) return;
    _hasAutoDispatched = true;

    final phone = user?.emergencyContactPhone.trim() ?? '';
    if (phone.isEmpty) {
      setState(() {
        _autoDispatchStatus =
            'No Emergency Contact phone saved in profile! Opening dialer...';
      });
      return;
    }

    setState(() {
      _autoDispatchStatus = 'Auto-dispatching SMS to $phone...';
    });

    try {
      // 1. Try 100% hands-free direct background SMS via Android SmsManager
      final bool sent = await _smsChannel.invokeMethod('sendDirectSms', {
        'phone': phone,
        'message': message,
      });
      if (sent && mounted) {
        setState(() {
          _autoDispatchStatus =
              '✅ HANDS-FREE SMS SENT AUTOMATICALLY TO ${user?.emergencyContactName.toUpperCase()} ($phone)';
        });
        return;
      }
    } catch (_) {
      // 2. Fallback: Automatically launch native SMS intent if permission not granted yet
      await SosService.sendEmergencySms(phone: phone, message: message);
      if (mounted) {
        setState(() {
          _autoDispatchStatus =
              '⚡ SMS App launched automatically for $phone (Grant SMS permission for silent send)';
        });
      }
    }
  }

  @override
  void dispose() {
    _strobeTimer?.cancel();
    _torchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user ??
        context.watch<AuthProvider>().userModel;
    final sos = context.watch<SosProvider>();

    // ── AUTOMATIC HANDS-FREE REACTIONS ──────────────────────────────
    // 1. Auto-turn ON Flashlight Strobe as soon as SOS Countdown or Alert starts
    if ((sos.state == SosState.countdown ||
            sos.state == SosState.generatingAlert ||
            sos.state == SosState.alertReady) &&
        !_isStrobeActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _startStrobeAutomatically();
      });
    }

    // 2. Auto-send SMS hands-free as soon as Gemini finishes generating the SOS payload
    if (sos.state == SosState.alertReady && !_hasAutoDispatched) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _autoSendEmergencySms(user, sos.sosMessage);
      });
    }

    // 3. Reset flags if user cancels/resets SOS
    if (sos.state == SosState.idle && _hasAutoDispatched) {
      _hasAutoDispatched = false;
      _autoDispatchStatus = '';
    }

    return Scaffold(
      backgroundColor: _screenFlashRed
          ? AppTheme.errorColor.withValues(alpha: 0.22)
          : AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Voice SOS & Auto-Dispatch'),
        backgroundColor: AppTheme.errorColor,
        foregroundColor: Colors.white,
        actions: [
          if (sos.state != SosState.idle || _isStrobeActive)
            TextButton(
              onPressed: () {
                _stopStrobe();
                sos.cancelSos();
              },
              child: const Text(
                'RESET',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Completely hidden Offstage camera controller for hardware LED torch
            Offstage(
              offstage: true,
              child: SizedBox(
                width: 1,
                height: 1,
                child: MobileScanner(controller: _torchController),
              ),
            ),

            // ── 1. TOP EMERGENCY CONTACT CARD (ALWAYS VISIBLE) ───────
            _EmergencyContactTopCard(user: user),
            const SizedBox(height: 12),

            // ── 2. STROBE FLASHLIGHT STATUS BAR (NO OVERLAP) ─────────
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _isStrobeActive
                    ? AppTheme.errorColor
                    : const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    _isStrobeActive
                        ? Icons.flashlight_on
                        : Icons.flashlight_off,
                    color: Colors.amberAccent,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Auto-Strobe Flashlight Beacon',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          _isStrobeActive
                              ? 'FLASHING NOW — Helping responders spot you'
                              : 'Turns ON automatically when Voice SOS triggers',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isStrobeActive,
                    activeThumbColor: Colors.amberAccent,
                    onChanged: (_) => _toggleEmergencyStrobe(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── 3. MAIN VOICE / COUNTDOWN / AUTO-DISPATCH CARDS ──────
            if (sos.state == SosState.countdown)
              _buildCountdownCard(sos)
            else if (sos.state == SosState.generatingAlert)
              const Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
                child: Padding(
                  padding: EdgeInsets.all(28),
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: AppTheme.errorColor),
                      SizedBox(height: 14),
                      Text(
                        'Locking GPS & Auto-Sending Emergency SMS...',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (sos.state == SosState.alertReady)
              _buildAlertReadyCard(context, sos, user)
            else
              _buildVoiceHub(sos, user),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceHub(SosProvider sos, UserModel? user) {
    final isListening = sos.isListening;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            isListening
                ? 'Listening Hands-Free... Speak Any Trigger Word'
                : 'Hands-Free Voice SOS Assistant',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Automatically flashes LED strobe & dispatches GPS SMS to your Emergency Contact',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 22),

          // Pulsing Microphone Button
          GestureDetector(
            onTap: () => isListening
                ? sos.stopVoiceListening()
                : sos.startVoiceListening(user: user),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isListening
                    ? AppTheme.sosGradient
                    : AppTheme.idCardGradient,
                boxShadow: [
                  BoxShadow(
                    color: (isListening
                            ? AppTheme.errorColor
                            : AppTheme.primaryColor)
                        .withValues(alpha: 0.38),
                    blurRadius: isListening ? 26 : 12,
                    spreadRadius: isListening ? 6 : 2,
                  ),
                ],
              ),
              child: Icon(
                isListening ? Icons.mic : Icons.mic_none,
                color: Colors.white,
                size: 48,
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (sos.recognizedWords.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Heard: "${sos.recognizedWords}"',
                style:
                    const TextStyle(fontStyle: FontStyle.italic, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 14),
          ],

          // ── Restored Voice Trigger Suggestion Chips ─────────────────
          const Text(
            'Voice Trigger Keywords:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: _triggerKeywords.map((word) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.errorColor.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  word,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.errorColor,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Manual Instant SOS Trigger Button
          ElevatedButton.icon(
            onPressed: () => sos.startSosCountdown(
              user: user,
              spokenContext: 'Manual Instant SOS Triggered',
            ),
            icon: const Icon(Icons.emergency_share, size: 18),
            label: const Text('TRIGGER AUTO-SOS NOW'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownCard(SosProvider sos) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.sosGradient,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.flashlight_on, color: Colors.amberAccent, size: 18),
              SizedBox(width: 6),
              Text(
                'STROBE ON · AUTO-SENDING SMS IN',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${sos.countdownSeconds}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 60,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              _stopStrobe();
              sos.cancelSos();
            },
            icon: const Icon(Icons.close),
            label: const Text('I AM SAFE — CANCEL'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.errorColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertReadyCard(
      BuildContext context, SosProvider sos, UserModel? user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.errorColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_autoDispatchStatus.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _autoDispatchStatus,
                style: const TextStyle(
                  color: AppTheme.successColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
          ],
          const Text(
            'AI Emergency SOS Payload Dispatched',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SelectableText(
              sos.sosMessage,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => SosService.sendEmergencySms(
              phone: user?.emergencyContactPhone ?? '',
              message: sos.sosMessage,
            ),
            icon: const Icon(Icons.sms),
            label: const Text('Resend SMS via Messaging App'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => SosService.callNumber('108'),
            icon: const Icon(Icons.call, color: AppTheme.errorColor),
            label: const Text('Call 108 Emergency Ambulance'),
          ),
        ],
      ),
    );
  }
}

class _EmergencyContactTopCard extends StatelessWidget {
  final UserModel? user;

  const _EmergencyContactTopCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final phone = user?.emergencyContactPhone.trim() ?? '';
    final name = user?.emergencyContactName.trim() ?? '';
    final relation = user?.emergencyContactRelation.trim() ?? '';
    final hasContact = phone.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: hasContact
            ? AppTheme.primaryColor.withValues(alpha: 0.08)
            : AppTheme.errorColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasContact
              ? AppTheme.primaryColor.withValues(alpha: 0.3)
              : AppTheme.errorColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (hasContact ? AppTheme.primaryColor : AppTheme.errorColor)
                  .withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasContact ? Icons.contact_phone : Icons.warning_amber_rounded,
              color: hasContact ? AppTheme.primaryColor : AppTheme.errorColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Emergency Contact',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  hasContact
                      ? '$name ${relation.isNotEmpty ? "($relation)" : ""}'
                      : 'No Emergency Contact Set',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                if (hasContact)
                  Text(
                    phone,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          if (hasContact)
            IconButton(
              icon: const Icon(Icons.call, color: AppTheme.primaryColor),
              onPressed: () => SosService.callNumber(phone),
            ),
        ],
      ),
    );
  }
}
