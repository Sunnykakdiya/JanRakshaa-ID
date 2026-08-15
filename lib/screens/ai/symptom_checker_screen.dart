import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/gemini_service.dart';
import '../../models/user_model.dart';
import '../../widgets/ai_response_card.dart';

class SymptomCheckerScreen extends StatefulWidget {
  const SymptomCheckerScreen({super.key});

  @override
  State<SymptomCheckerScreen> createState() => _SymptomCheckerScreenState();
}

class _SymptomCheckerScreenState extends State<SymptomCheckerScreen> {
  final _symptomsCtrl = TextEditingController();
  final _gemini = GeminiService();

  bool _isLoading = false;
  String? _response;
  String? _error;

  @override
  void dispose() {
    _symptomsCtrl.dispose();
    super.dispose();
  }

  UserModel? get _user {
    final up = context.read<UserProvider>().user;
    return up ?? context.read<AuthProvider>().userModel;
  }

  Future<void> _analyze() async {
    final symptoms = _symptomsCtrl.text.trim();
    if (symptoms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please describe your symptoms first'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final user = _user;
    if (user == null) return;

    setState(() {
      _isLoading = true;
      _response = null;
      _error = null;
    });

    try {
      final result = await _gemini.analyzeSymptoms(
        symptoms: symptoms,
        user: user,
      );
      setState(() {
        _response = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _retry() => _analyze();

  void _clear() {
    setState(() {
      _response = null;
      _error = null;
      _isLoading = false;
    });
    _symptomsCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.select<UserProvider, UserModel?>(
          (p) => p.user,
    ) ??
        context.select<AuthProvider, UserModel?>(
              (p) => p.userModel,
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Symptom Checker'),
        actions: [
          if (_response != null || _error != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _clear,
              tooltip: 'Clear & Start Over',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── AI Banner ──────────────────────────────────
            _AIBanner(),
            const SizedBox(height: 20),

            // ── User Medical Context ───────────────────────
            if (user != null) ...[
              _MedicalContextCard(user: user),
              const SizedBox(height: 20),
            ],

            // ── Symptom Input ──────────────────────────────
            Text('Describe Your Symptoms',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              'Be as specific as possible — location, severity, duration.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _symptomsCtrl,
              maxLines: 5,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText:
                'e.g. Severe headache on the left side for 2 hours, light sensitivity, some nausea...',
                hintStyle: const TextStyle(
                    fontSize: 13, color: AppTheme.textSecondary),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                  const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                  const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                      color: AppTheme.primaryColor, width: 2),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),

            const SizedBox(height: 16),

            // ── Quick Symptom Chips ────────────────────────
            _QuickSymptomChips(
              onSelect: (s) {
                final current = _symptomsCtrl.text;
                _symptomsCtrl.text =
                current.isEmpty ? s : '$current, $s';
              },
            ),

            const SizedBox(height: 20),

            // ── Analyze Button ─────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _analyze,
                icon: _isLoading
                    ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.psychology),
                label: Text(_isLoading
                    ? 'Analyzing...'
                    : 'Analyze with Gemini AI'),
              ),
            ),

            const SizedBox(height: 24),

            // ── AI Response ────────────────────────────────
            AiResponseCard(
              isLoading: _isLoading,
              response: _response,
              error: _error,
              onRetry: _retry,
            ),

            if (_response != null || _error != null)
              const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── AI Banner ─────────────────────────────────────────────────
class _AIBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Icon(Icons.psychology, color: Colors.white, size: 32),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Powered by Gemini AI',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                Text(
                  'AI considers your full medical profile when analyzing symptoms.',
                  style:
                  TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Medical Context Card ───────────────────────────────────────
class _MedicalContextCard extends StatelessWidget {
  final UserModel user;
  const _MedicalContextCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.medical_information,
                  color: AppTheme.primaryColor, size: 18),
              const SizedBox(width: 8),
              Text(
                'Your Profile Context (sent to AI)',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (user.bloodGroup.isNotEmpty)
                _ContextChip('🩸 ${user.bloodGroup}', AppTheme.errorColor),
              ...user.allergies.map(
                      (a) => _ContextChip('⚠️ $a', Colors.orange)),
              ...user.medications.map(
                      (m) => _ContextChip('💊 $m', AppTheme.primaryColor)),
              ...user.conditions
                  .map((c) => _ContextChip('🏥 $c', Colors.purple)),
              if (user.bloodGroup.isEmpty &&
                  user.allergies.isEmpty &&
                  user.medications.isEmpty &&
                  user.conditions.isEmpty)
                Text(
                  'No medical info in profile yet. Add it for better AI context.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                      fontStyle: FontStyle.italic),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContextChip extends StatelessWidget {
  final String label;
  final Color color;
  const _ContextChip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w500)),
    );
  }
}

// ── Quick Symptom Chips ───────────────────────────────────────
class _QuickSymptomChips extends StatelessWidget {
  final Function(String) onSelect;
  const _QuickSymptomChips({required this.onSelect});

  static const _symptoms = [
    'Headache',
    'Fever',
    'Chest pain',
    'Shortness of breath',
    'Nausea',
    'Dizziness',
    'Fatigue',
    'Stomach pain',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Add:',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: _symptoms
              .map((s) => GestureDetector(
            onTap: () => onSelect(s),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color:
                    AppTheme.primaryColor.withValues(alpha: 0.3)),
              ),
              child: Text(s,
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.primaryColor)),
            ),
          ))
              .toList(),
        ),
      ],
    );
  }
}