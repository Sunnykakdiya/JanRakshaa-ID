import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
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
  final _gemini = GeminiService();

  // Profile medications (pre-loaded) + user-added ones
  late List<String> _profileMeds;
  final List<String> _extraMeds = [];

  bool _isLoading = false;
  String? _response;
  String? _error;

  @override
  void initState() {
    super.initState();
    final user = context.read<UserProvider>().user ??
        context.read<AuthProvider>().userModel;
    _profileMeds = List.from(user?.medications ?? []);
  }

  @override
  void dispose() {
    _addCtrl.dispose();
    super.dispose();
  }

  List<String> get _allMeds => [..._profileMeds, ..._extraMeds];

  void _addMed() {
    final val = _addCtrl.text.trim();
    if (val.isEmpty) return;
    if (_allMeds.any((m) => m.toLowerCase() == val.toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Already in the list')),
      );
      return;
    }
    setState(() => _extraMeds.add(val));
    _addCtrl.clear();
  }

  void _removeExtra(String med) {
    setState(() => _extraMeds.remove(med));
    // Reset results when list changes
    if (_response != null || _error != null) {
      setState(() {
        _response = null;
        _error = null;
      });
    }
  }

  Future<void> _check() async {
    if (_allMeds.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least 2 medications to check'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _response = null;
      _error = null;
    });

    try {
      final result = await _gemini.checkDrugInteractions(_allMeds);
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

  void _clear() {
    setState(() {
      _extraMeds.clear();
      _response = null;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drug Interaction Checker'),
        actions: [
          if (_extraMeds.isNotEmpty || _response != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _clear,
              tooltip: 'Clear extra meds & results',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Banner ─────────────────────────────────────
            _Banner(),
            const SizedBox(height: 20),

            // ── Profile Medications ────────────────────────
            Text('Your Profile Medications',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),

            if (_profileMeds.isEmpty)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: Colors.orange, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'No medications in your profile. Add them below or go to Edit Profile.',
                        style: TextStyle(
                            color: Colors.orange, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _profileMeds
                    .map((med) => _MedChip(
                  label: med,
                  isProfile: true,
                  onRemove: null, // profile meds can't be removed here
                ))
                    .toList(),
              ),

            const SizedBox(height: 20),

            // ── Add Extra Medications ──────────────────────
            Text('Add Extra Medications',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              'Add over-the-counter, supplements, or other medications not in your profile.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _addCtrl,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _addMed(),
                    decoration: InputDecoration(
                      hintText: 'e.g. Aspirin 100mg',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                        const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                        const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppTheme.primaryColor, width: 2),
                      ),
                      contentPadding:
                      const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _addMed,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child:
                    const Icon(Icons.add, color: Colors.white, size: 22),
                  ),
                ),
              ],
            ),

            if (_extraMeds.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _extraMeds
                    .map((med) => _MedChip(
                  label: med,
                  isProfile: false,
                  onRemove: () => _removeExtra(med),
                ))
                    .toList(),
              ),
            ],

            // ── All Meds Summary ───────────────────────────
            if (_allMeds.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.medication,
                        color: AppTheme.primaryColor, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Checking ${_allMeds.length} medication${_allMeds.length == 1 ? '' : 's'}: ${_allMeds.join(', ')}',
                      style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // ── Check Button ───────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _check,
                icon: _isLoading
                    ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.search),
                label: Text(_isLoading
                    ? 'Checking Interactions...'
                    : 'Check Interactions with AI'),
              ),
            ),

            const SizedBox(height: 24),

            // ── AI Response ────────────────────────────────
            AiResponseCard(
              isLoading: _isLoading,
              response: _response,
              error: _error,
              onRetry: _check,
            ),

            if (_response != null || _error != null)
              const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── Banner ─────────────────────────────────────────────────────
class _Banner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.purple.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.purple.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.medication,
                color: Colors.purple, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Drug Interaction Checker',
                    style: TextStyle(
                        color: Colors.purple,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                Text(
                  'Uses Gemini to identify potentially dangerous combinations.',
                  style: TextStyle(
                      color: Colors.purple, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Medication Chip ─────────────────────────────────────────────
class _MedChip extends StatelessWidget {
  final String label;
  final bool isProfile;
  final VoidCallback? onRemove;

  const _MedChip({
    required this.label,
    required this.isProfile,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final color = isProfile ? AppTheme.primaryColor : Colors.purple;
    return Container(
      padding: EdgeInsets.fromLTRB(12, 6, onRemove != null ? 4 : 12, 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isProfile ? Icons.person_outline : Icons.add_circle_outline,
            color: color,
            size: 14,
          ),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
          if (onRemove != null) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onRemove,
              child: Icon(Icons.close, color: color, size: 16),
            ),
          ],
        ],
      ),
    );
  }
}