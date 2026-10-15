import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../services/gemini_service.dart';
import '../../widgets/loading_button.dart';

class GeminiKeyScreen extends StatefulWidget {
  const GeminiKeyScreen({super.key});

  @override
  State<GeminiKeyScreen> createState() => _GeminiKeyScreenState();
}

class _GeminiKeyScreenState extends State<GeminiKeyScreen> {
  final _keyCtrl = TextEditingController();
  bool _obscure = true;
  bool _isSaving = false;
  bool _isTesting = false;
  bool _hasSavedKey = false;
  String? _statusMsg;
  bool _statusIsSuccess = false;

  @override
  void initState() {
    super.initState();
    _loadExistingKey();
  }

  @override
  void dispose() {
    _keyCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExistingKey() async {
    final key = await GeminiService.getApiKey();
    if (key != null && key.isNotEmpty) {
      setState(() {
        _keyCtrl.text = key;
        _hasSavedKey = true;
      });
    }
  }

  Future<void> _testKey() async {
    final key = _keyCtrl.text.trim();
    if (key.isEmpty) {
      _setStatus('Enter an API key first', false);
      return;
    }
    setState(() {
      _isTesting = true;
      _statusMsg = null;
    });
    final error = await GeminiService.testApiKey(key);

    if (error == null) {
      await GeminiService.saveApiKey(key);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gemini API key verified successfully!'),
          ),
        );
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
          ),
        );
      }
    }
  }

  Future<void> _saveKey() async {
    final key = _keyCtrl.text.trim();
    if (key.isEmpty) {
      _setStatus('Please enter your API key', false);
      return;
    }
    setState(() => _isSaving = true);
    await GeminiService.saveApiKey(key);
    setState(() {
      _isSaving = false;
      _hasSavedKey = true;
    });
    _setStatus('✅ API key saved successfully!', true);
    if (mounted) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) Navigator.pop(context, true); // true = key was set
    }
  }

  Future<void> _clearKey() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear API Key'),
        content: const Text('Remove the saved Gemini API key? AI features will stop working.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
            ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await GeminiService.clearApiKey();
      setState(() {
        _keyCtrl.clear();
        _hasSavedKey = false;
        _statusMsg = null;
      });
    }
  }

  void _setStatus(String msg, bool success) {
    setState(() {
      _statusMsg = msg;
      _statusIsSuccess = success;
    });
  }

  Future<void> _openAiStudio() async {
    final uri = Uri.parse(AppConstants.geminiStudioUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gemini AI Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── What is this ──────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.psychology,
                          color: AppTheme.primaryColor, size: 22),
                      const SizedBox(width: 10),
                      Text('Google Gemini AI',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(color: AppTheme.primaryColor)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'JanRaksha uses Gemini for AI features:\n'
                        '• Symptom Checker\n'
                        '• Drug Interaction Checker\n'
                        '• Emergency Brief Generator\n'
                        '• (More in Phase 4–8)',
                    style: TextStyle(
                        fontSize: 13,
                        height: 1.6,
                        color: AppTheme.textPrimary),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── How to get the key ────────────────────────────
            Text('How to get your free API key',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),

            _Step(
              number: '1',
              text: 'Go to Google AI Studio',
              action: TextButton.icon(
                onPressed: _openAiStudio,
                icon: const Icon(Icons.open_in_browser, size: 16),
                label: const Text('Open AI Studio'),
              ),
            ),
            const _Step(
              number: '2',
              text: 'Sign in with your Google account',
            ),
            const _Step(
              number: '3',
              text: 'Click "Get API key" → "Create API key"',
            ),
            const _Step(
              number: '4',
              text: 'Copy the key and paste it below',
            ),

            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '✅ Free tier: 15 requests/min, 1500/day — plenty for a portfolio app.',
                style: TextStyle(
                    color: AppTheme.successColor, fontSize: 12),
              ),
            ),

            const SizedBox(height: 28),

            // ── API Key Input ─────────────────────────────────
            Text('Your API Key',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),

            TextField(
              controller: _keyCtrl,
              obscureText: _obscure,
              decoration: InputDecoration(
                hintText: 'AIzaSy...',
                labelText: 'Gemini API Key',
                prefixIcon: const Icon(Icons.key_outlined, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(_obscure
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
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
              ),
            ),

            const SizedBox(height: 16),

            // ── Status message ────────────────────────────────
            if (_statusMsg != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (_statusIsSuccess
                      ? AppTheme.successColor
                      : AppTheme.errorColor)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: (_statusIsSuccess
                          ? AppTheme.successColor
                          : AppTheme.errorColor)
                          .withValues(alpha: 0.4)),
                ),
                child: Text(
                  _statusMsg!,
                  style: TextStyle(
                      color: _statusIsSuccess
                          ? AppTheme.successColor
                          : AppTheme.errorColor,
                      fontSize: 13),
                ),
              ),

            const SizedBox(height: 20),

            // ── Buttons ───────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isTesting ? null : _testKey,
                    icon: _isTesting
                        ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2))
                        : const Icon(Icons.wifi_tethering),
                    label: Text(_isTesting ? 'Testing...' : 'Test Key'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 50),
                      side: const BorderSide(
                          color: AppTheme.primaryColor),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: LoadingButton(
                    text: _hasSavedKey ? 'Update Key' : 'Save Key',
                    isLoading: _isSaving,
                    onPressed: _saveKey,
                    icon: Icons.save_outlined,
                  ),
                ),
              ],
            ),

            if (_hasSavedKey) ...[
              const SizedBox(height: 12),
              Center(
                child: TextButton.icon(
                  onPressed: _clearKey,
                  icon: const Icon(Icons.delete_outline,
                      color: AppTheme.errorColor),
                  label: const Text('Clear saved key',
                      style: TextStyle(color: AppTheme.errorColor)),
                ),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String number;
  final String text;
  final Widget? action;
  const _Step({required this.number, required this.text, this.action});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: const BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(number,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text,
                    style: const TextStyle(fontSize: 13, height: 1.6)),
                if (action != null) action!,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
