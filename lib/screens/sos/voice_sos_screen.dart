import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/sos_provider.dart';
import '../../services/sos_service.dart';

class VoiceSosScreen extends StatelessWidget {
  const VoiceSosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user ??
        context.watch<AuthProvider>().userModel;
    final sos = context.watch<SosProvider>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Voice SOS Alert'),
        backgroundColor: AppTheme.accentColor,
        foregroundColor: Colors.white,
        actions: [
          if (sos.state != SosState.idle)
            TextButton(
              onPressed: sos.cancelSos,
              child: const Text(
                'RESET',
                style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Emergency Contact Banner ───────────────────────────
            _EmergencyContactBanner(user: user),
            const SizedBox(height: 20),

            // ── Main Interactive State Area ────────────────────────
            if (sos.state == SosState.countdown)
              _CountdownCard(sos: sos)
            else if (sos.state == SosState.generatingAlert)
              const _GeneratingAlertCard()
            else if (sos.state == SosState.alertReady)
                _AlertReadyCard(sos: sos, user: user)
              else
                _VoiceTriggerHub(sos: sos, user: user),

            if (sos.error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  sos.error!,
                  style: const TextStyle(
                      color: AppTheme.errorColor, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Emergency Contact Header Card ──────────────────────────────────────
class _EmergencyContactBanner extends StatelessWidget {
  final UserModel? user;
  const _EmergencyContactBanner({required this.user});

  @override
  Widget build(BuildContext context) {
    final hasContact =
        user != null && user!.emergencyContactPhone.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasContact
              ? AppTheme.successColor.withValues(alpha: 0.4)
              : Colors.orange.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: hasContact
                ? AppTheme.successColor.withValues(alpha: 0.12)
                : Colors.orange.withValues(alpha: 0.12),
            child: Icon(
              hasContact ? Icons.contact_phone : Icons.warning_amber_rounded,
              color: hasContact ? AppTheme.successColor : Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasContact
                      ? 'Emergency Contact: ${user!.emergencyContactName}'
                      : 'No Emergency Contact Saved',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  hasContact
                      ? '${user!.emergencyContactPhone} (${user!.emergencyContactRelation})'
                      : 'Update your profile to auto-send SMS alerts.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          if (hasContact)
            IconButton(
              icon: const Icon(Icons.call, color: AppTheme.successColor),
              tooltip: 'Call Emergency Contact',
              onPressed: () =>
                  SosService.callNumber(user!.emergencyContactPhone),
            ),
        ],
      ),
    );
  }
}

// ── Voice Listener & Manual SOS Hub ────────────────────────────────────
class _VoiceTriggerHub extends StatelessWidget {
  final SosProvider sos;
  final UserModel? user;

  const _VoiceTriggerHub({required this.sos, required this.user});

  @override
  Widget build(BuildContext context) {
    final isListening = sos.isListening;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                isListening
                    ? 'Listening for Emergency Trigger...'
                    : 'Hands-Free Voice SOS',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Tap the microphone and say any trigger word aloud',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Big Mic Button
              GestureDetector(
                onTap: () => isListening
                    ? sos.stopVoiceListening()
                    : sos.startVoiceListening(user: user),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isListening
                        ? AppTheme.errorColor
                        : AppTheme.primaryColor,
                    boxShadow: [
                      BoxShadow(
                        color: (isListening
                            ? AppTheme.errorColor
                            : AppTheme.primaryColor)
                            .withValues(alpha: 0.35),
                        blurRadius: isListening ? 28 : 14,
                        spreadRadius: isListening ? 6 : 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    isListening ? Icons.mic : Icons.mic_none,
                    color: Colors.white,
                    size: 54,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              if (sos.recognizedWords.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '"${sos.recognizedWords}"',
                    style: const TextStyle(
                        fontStyle: FontStyle.italic, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 16),
              const Text(
                'Supported Voice Trigger Words:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: SosService.triggerWords
                    .map(
                      (w) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color:
                          AppTheme.accentColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '"${w.toUpperCase()}"',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentColor,
                      ),
                    ),
                  ),
                )
                    .toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Instant Manual SOS Trigger Button
        ElevatedButton.icon(
          onPressed: () => sos.startSosCountdown(
              user: user, spokenContext: 'Manual SOS Button Pressed'),
          icon: const Icon(Icons.emergency_share, size: 24),
          label: const Text(
            'TRIGGER INSTANT SOS NOW',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.errorColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }
}

// ── 5-Second Safety Countdown Card ─────────────────────────────────────
class _CountdownCard extends StatelessWidget {
  final SosProvider sos;
  const _CountdownCard({required this.sos});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.errorColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          if (sos.detectedTrigger != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Trigger Detected: "${sos.detectedTrigger}"',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          const Text(
            'Sending Emergency Alert In',
            style: TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            '${sos.countdownSeconds}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 64,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Fetching GPS Location & Generating AI Medical Brief...',
            style: TextStyle(color: Colors.white70, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: sos.cancelSos,
            icon: const Icon(Icons.close),
            label: const Text('I AM SAFE — CANCEL SOS'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.errorColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Loading State While Fetching GPS & Gemini Response ─────────────────
class _GeneratingAlertCard extends StatelessWidget {
  const _GeneratingAlertCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        children: [
          CircularProgressIndicator(color: AppTheme.errorColor),
          SizedBox(height: 20),
          Text(
            'Acquiring GPS & Generating AI SOS Message...',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Alert Ready & Dispatch Card ────────────────────────────────────────
class _AlertReadyCard extends StatelessWidget {
  final SosProvider sos;
  final UserModel? user;

  const _AlertReadyCard({required this.sos, required this.user});

  @override
  Widget build(BuildContext context) {
    final pos = sos.currentPosition;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.errorColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.emergency, color: AppTheme.errorColor, size: 28),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'AI Emergency SOS Ready',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on,
                    color: AppTheme.primaryColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    pos != null
                        ? 'GPS: ${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}'
                        : 'GPS Location Unavailable',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Generated SOS Message:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SelectableText(
              sos.sosMessage,
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              final phone = user?.emergencyContactPhone ?? '';
              if (phone.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Please add an emergency contact phone in your profile.'),
                  ),
                );
                return;
              }
              SosService.sendEmergencySms(
                  phone: phone, message: sos.sosMessage);
            },
            icon: const Icon(Icons.sms),
            label: const Text('Send SOS SMS to Emergency Contact'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => SosService.callNumber('108'),
            icon: const Icon(Icons.local_hospital, color: AppTheme.errorColor),
            label: const Text(
              'Call 108 Ambulance',
              style: TextStyle(
                  color: AppTheme.errorColor, fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.errorColor),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}