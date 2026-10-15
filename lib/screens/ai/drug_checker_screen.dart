import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/gemini_service.dart';
import '../../widgets/ai_response_card.dart';

class DrugCheckerScreen extends StatefulWidget {
  const DrugCheckerScreen({super.key});

  @override
  State<DrugCheckerScreen> createState() => _DrugCheckerScreenState();
}

class _DrugCheckerScreenState extends State<DrugCheckerScreen> {
  final _addCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  List<String> _medications = [];
  bool _isLoading = false;
  String? _response;
  String? _error;
  bool _profileLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pre-load profile medications once
    if (!_profileLoaded) {
      _profileLoaded = true;
      final user = context.read<UserProvider>().user ??
          context.read<AuthProvider>().userModel;
      if (user != null && user.medications.isNotEmpty) {
        setState(() => _medications = List.from(user.medications));
      }
    }
  }

  @override
  void dispose() {
    _addCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _addMedication() {
    final val = _addCtrl.text.trim();
    if (val.isEmpty) return;
    final alreadyExists =
    _medications.any((m) => m.toLowerCase() == val.toLowerCase());
    if (alreadyExists) {
      _addCtrl.clear();
      return;
    }
    setState(() {
      _medications.add(val);
      _addCtrl.clear();
    });
  }

  void _remove(String med) =>
      setState(() => _medications.remove(med));

  Future<void> _checkInteractions() async {
    if (_medications.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least 2 medications to check interactions'),
        ),
      );
      return;
    }

    final hasKey = await GeminiService.hasApiKey();
    if (!hasKey && mounted) {
      _showNoKeyDialog();
      return;
    }

    setState(() {
      _isLoading = true;
      _response = null;
      _error = null;
    });

    try {
      final result = await GeminiService.checkDrugInteractions(
        medications: _medications,
      );
      setState(() {
        _response = result;
        _isLoading = false;
      });
      await Future.delayed(const Duration(milliseconds: 200));
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    } on GeminiException catch (e) {
      setState(() {
        _error = e.userMessage;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _error = 'Something went wrong. Check your connection.';
        _isLoading = false;
      });
    }
  }

  void _showNoKeyDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('API Key Required'),
        content: const Text(
            'Set up your free Gemini API key to use AI features.'),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Later')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(
                  context, AppConstants.geminiSettingsRoute);
            },
            child: const Text('Set Up Now'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drug Interaction Checker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.pushNamed(
                context, AppConstants.geminiSettingsRoute),
            tooltip: 'Gemini Settings',
          ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollCtrl,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────
            _FeatureHeader(),
            const SizedBox(height: 24),

            // ── Medication List ────────────────────────────────
            Row(
              children: [
                Text('Medications to check',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontSize: 15)),
                const Spacer(),
                if (_medications.isNotEmpty)
                  Text('${_medications.length} added',
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 12),

            // Medication chips
            if (_medications.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _medications
                    .map((med) => Chip(
                  label: Text(med,
                      style: const TextStyle(fontSize: 13)),
                  backgroundColor:
                  AppTheme.primaryColor.withValues(alpha: 0.08),
                  deleteIcon:
                  const Icon(Icons.close, size: 16),
                  deleteIconColor: AppTheme.primaryColor,
                  side: BorderSide(
                      color: AppTheme.primaryColor
                          .withValues(alpha: 0.3)),
                  onDeleted: () => _remove(med),
                ))
                    .toList(),
              ),
              const SizedBox(height: 14),
            ],

            // Profile medications hint
            if (_medications.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '💊 Medications from your profile are pre-loaded. Add more below to check interactions.',
                  style: TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12),
                ),
              ),

            const SizedBox(height: 14),

            // ── Add Medication Input ───────────────────────────
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _addCtrl,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _addMedication(),
                    decoration: InputDecoration(
                      hintText: 'e.g. Aspirin 75mg',
                      labelText: 'Add medication',
                      prefixIcon: const Icon(
                          Icons.medication_outlined,
                          size: 20),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFFE5E7EB))),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFFE5E7EB))),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: AppTheme.primaryColor,
                              width: 2)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _addMedication,
                  child: Container(
                    height: 54,
                    width: 54,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.add,
                        color: Colors.white, size: 24),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),
            const Text(
              'Include brand name or generic name, plus dosage if known.',
              style: TextStyle(
                  color: AppTheme.textSecondary, fontSize: 11),
            ),

            const SizedBox(height: 12),

            // ── Common Medications Quick-Add ──────────────────
            const Text('Quick add common:',
                style: TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _commonMeds
                  .where((m) => !_medications.contains(m))
                  .take(8)
                  .map((m) => GestureDetector(
                onTap: () => setState(() {
                  if (!_medications.contains(m)) {
                    _medications.add(m);
                  }
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppTheme.primaryColor
                            .withValues(alpha: 0.3)),
                  ),
                  child: Text('+ $m',
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.primaryColor)),
                ),
              ))
                  .toList(),
            ),

            const SizedBox(height: 24),

            // ── Check Button ───────────────────────────────────
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _checkInteractions,
              icon: _isLoading
                  ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.science_outlined),
              label: Text(_isLoading
                  ? 'Checking...'
                  : 'Check Interactions (${_medications.length} meds)'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),

            const SizedBox(height: 28),

            // ── Error ──────────────────────────────────────────
            if (_error != null)
              _ErrorBanner(
                  message: _error!,
                  onSettingsTap: _error!.contains('key')
                      ? () => Navigator.pushNamed(
                      context, AppConstants.geminiSettingsRoute)
                      : null),

            // ── AI Response ────────────────────────────────────
            if (_response != null) ...[
              AiResponseCard(
                response: _response!,
                title: 'Drug Interaction Analysis',
              ),
              const SizedBox(height: 16),
              Center(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _response = null),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Check Different Medications'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                        color: AppTheme.primaryColor),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  static const List<String> _commonMeds = [
    'Aspirin',
    'Paracetamol',
    'Metformin',
    'Amlodipine',
    'Atorvastatin',
    'Omeprazole',
    'Clopidogrel',
    'Warfarin',
    'Insulin',
    'Metoprolol',
  ];
}

// ── Feature Header ─────────────────────────────────────────────────────
class _FeatureHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.08),
            Colors.orange.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.science_outlined,
                color: Colors.orange, size: 28),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Drug Interaction Checker',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppTheme.primaryColor)),
                SizedBox(height: 4),
                Text(
                  'Checks if your medications are safe to take together. Profile meds are pre-loaded.',
                  style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error Banner ───────────────────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onSettingsTap;

  const _ErrorBanner({required this.message, this.onSettingsTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.errorColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border:
          Border.all(color: AppTheme.errorColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline,
                color: AppTheme.errorColor, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message,
                  style: const TextStyle(
                      color: AppTheme.errorColor, fontSize: 13)),
            ),
            if (onSettingsTap != null)
              TextButton(
                onPressed: onSettingsTap,
                child: const Text('Fix'),
              ),
          ],
        ),
      ),
    );
  }
}
