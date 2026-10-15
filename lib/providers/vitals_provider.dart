import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../models/vitals_model.dart';
import '../models/user_model.dart';
import '../services/vitals_service.dart';

class VitalsProvider extends ChangeNotifier {
  final VitalsService _vitalsService = VitalsService();
  StreamSubscription<User?>? _authSub;
  StreamSubscription<List<VitalsEntry>>? _vitalsSub;

  List<VitalsEntry> _entries = [];
  bool _isLoading = false;
  VitalsAlert? _lastAnalysis;
  bool _isAnalyzing = false;
  String? _error;

  List<VitalsEntry> get entries => _entries;
  bool get isLoading => _isLoading;
  VitalsAlert? get lastAnalysis => _lastAnalysis;
  bool get isAnalyzing => _isAnalyzing;
  String? get error => _error;

  VitalsProvider() {
    _listenToAuth();
  }

  void _listenToAuth() {
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _subscribeToVitals(user.uid);
      } else {
        _vitalsSub?.cancel();
        _entries = [];
        _lastAnalysis = null;
        notifyListeners();
      }
    });
  }

  void _subscribeToVitals(String uid) {
    _isLoading = true;
    notifyListeners();

    _vitalsSub?.cancel();
    _vitalsSub = _vitalsService.getVitalsStream(uid).listen(
          (entries) {
        _entries = entries;
        _isLoading = false;
        notifyListeners();
      },
      onError: (_) {
        _error = 'Failed to load vitals history.';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<bool> addVitals(VitalsEntry entry) async {
    _error = null;
    try {
      await _vitalsService.saveVitals(entry);
      return true;
    } catch (_) {
      _error = 'Failed to save vitals. Try again.';
      notifyListeners();
      return false;
    }
  }

  Future<void> analyzeWithAI({UserModel? user}) async {
    if (_entries.length < 2) {
      _error = 'Log at least 2 readings for AI trend analysis.';
      notifyListeners();
      return;
    }

    _isAnalyzing = true;
    _error = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final apiKey = prefs.getString(AppConstants.geminiApiKeyPref) ?? '';

      if (apiKey.isEmpty) {
        _error = 'Please set your Gemini API key in Settings first.';
        _isAnalyzing = false;
        notifyListeners();
        return;
      }

      final recentEntries = _entries.take(14).toList();
      final buffer = StringBuffer();

      if (user != null) {
        buffer.writeln(
            'Patient Info: Gender: ${user.gender}, Blood: ${user.bloodGroup}, Conditions: ${user.conditions.join(", ")}');
      }
      buffer.writeln('Vitals Readings (newest to oldest):');
      for (final r in recentEntries) {
        final dateStr =
            '${r.timestamp.day}/${r.timestamp.month}/${r.timestamp.year}';
        buffer.writeln(
          '- [$dateStr] HR: ${r.heartRate} bpm, BP: ${r.systolicBP}/${r.diastolicBP} mmHg, '
              'Glucose: ${r.glucoseLevel} mmol/L, Weight: ${r.weight} kg (Status: ${r.alertLevel})',
        );
      }

      final prompt = '''
You are a medical AI assistant. Analyze the patient's vitals history below and respond STRICTLY in this exact format:

ANOMALY_DETECTED: [YES or NO]
TREND_SUMMARY:
[2-3 sentences summarizing the overall trajectory across heart rate, blood pressure, glucose, and weight]
CONCERNING_FINDINGS:
- [Bullet point 1, or write "None detected" if everything is stable]
RECOMMENDATION:
[Clear, actionable advice for the patient]

${buffer.toString()}
''';

      final model = GenerativeModel(
        model: AppConstants.geminiModel,
        apiKey: apiKey,
      );

      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text;

      if (text == null || text.isEmpty) {
        _error = 'Empty response from Gemini AI.';
      } else {
        _lastAnalysis = VitalsAlert.fromGeminiResponse(text);
      }
    } catch (e) {
      _error = 'Analysis failed. Check your API key or internet connection.';
    }

    _isAnalyzing = false;
    notifyListeners();
  }

  Future<void> deleteEntry(String uid, String entryId) async {
    try {
      await _vitalsService.deleteVitals(uid, entryId);
    } catch (_) {
      _error = 'Failed to delete entry.';
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _vitalsSub?.cancel();
    super.dispose();
  }
}