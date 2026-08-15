import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/user_model.dart';
import '../core/env.dart';

/// Wraps all Gemini API calls for JanRaksha's AI features.
/// Uses gemini-2.0-flash (fast + free tier).
class GeminiService {
  static const _model = 'gemini-3.1-flash-lite';

  late final GenerativeModel _gemini;

  GeminiService() {
    _gemini = GenerativeModel(
      model: _model,
      apiKey: Env.geminiApiKey,
    );
  }

  // ── 1. Emergency Summary (shown on QR screen) ─────────────

  Future<String> generateEmergencySummary(UserModel user) async {
    final prompt = '''
You are an emergency medical AI generating a brief for first responders.

Patient profile:
- Name: ${user.name}
- Blood Group: ${user.bloodGroup.isEmpty ? 'Unknown' : user.bloodGroup}
- Allergies: ${user.allergies.isEmpty ? 'None' : user.allergies.join(', ')}
- Current Medications: ${user.medications.isEmpty ? 'None' : user.medications.join(', ')}
- Medical Conditions: ${user.conditions.isEmpty ? 'None' : user.conditions.join(', ')}
- Emergency Contact: ${user.emergencyContactName} (${user.emergencyContactRelation}) · ${user.emergencyContactPhone}

Write a clear emergency brief under 80 words.
Priority order: blood type → allergies → medications → conditions → contact.
Use simple language. No markdown. No headers.
''';
    return _call(prompt, feature: 'emergency summary');
  }

  // ── 2. Symptom Checker ────────────────────────────────────

  Future<String> analyzeSymptoms({
    required String symptoms,
    required UserModel user,
  }) async {
    final prompt = '''
You are a medical AI assistant. Analyze symptoms while considering the patient's medical history.
This is informational only — always recommend seeing a doctor.

Patient context:
- Blood Group: ${user.bloodGroup.isEmpty ? 'Unknown' : user.bloodGroup}
- Allergies: ${user.allergies.isEmpty ? 'None' : user.allergies.join(', ')}
- Current Medications: ${user.medications.isEmpty ? 'None' : user.medications.join(', ')}
- Pre-existing Conditions: ${user.conditions.isEmpty ? 'None' : user.conditions.join(', ')}

Reported symptoms: $symptoms

Respond in EXACTLY this format (no extra lines):

SEVERITY: [Mild / Moderate / Severe / Emergency]

POSSIBLE CAUSES:
• [cause 1]
• [cause 2]
• [cause 3]

IMMEDIATE ACTIONS:
• [action 1]
• [action 2]
• [action 3]

SEEK EMERGENCY CARE: [Yes / No / If symptoms worsen]

IMPORTANT NOTE: [1 sentence considering patient's specific medical history]
''';
    return _call(prompt, feature: 'symptom analysis');
  }

  // ── 3. Drug Interaction Checker ───────────────────────────

  Future<String> checkDrugInteractions(List<String> medications) async {
    if (medications.length < 2) {
      return 'Please add at least 2 medications to check for interactions.';
    }

    final medList = medications.map((m) => '• $m').join('\n');
    final prompt = '''
You are a pharmacology AI. Check for drug interactions.

Medications:
$medList

Respond in EXACTLY this format:

INTERACTIONS FOUND: [Yes / No / Minor only]

DETAILS:
[List each interaction clearly, or write "No significant interactions found"]

SEVERITY: [None / Minor / Moderate / Major]

RECOMMENDATIONS:
• [recommendation 1]
• [recommendation 2]

DISCLAIMER: Always consult your doctor or pharmacist before changing medications.
''';
    return _call(prompt, feature: 'drug interaction check');
  }

  // ── 4. AI SOS Message Generator ──────────────────────────

  Future<String> generateSOSMessage({
    required String name,
    required String location,
    required String situation,
    required String bloodGroup,
    required String emergencyContactPhone,
  }) async {
    final prompt = '''
Write an urgent emergency SMS under 160 characters:
Person: $name
Location: $location
Situation: $situation
Blood Group: $bloodGroup
Contact: $emergencyContactPhone

Be extremely concise. Include only what a responder needs. No pleasantries.
''';
    try {
      return await _call(prompt, feature: 'SOS message');
    } catch (_) {
      // Fallback if API fails — critical for emergency
      return 'EMERGENCY: $name needs help at $location. Blood: $bloodGroup. Call: $emergencyContactPhone';
    }
  }

  // ── Internal ──────────────────────────────────────────────

  Future<String> _call(String prompt, {required String feature}) async {
    try {
      final response =
      await _gemini.generateContent([Content.text(prompt)]);
      final text = response.text;
      if (text == null || text.trim().isEmpty) {
        throw GeminiException('Empty response from AI for $feature');
      }
      return text.trim();
    } on GeminiException {
      rethrow;
    } catch (e) {
      throw GeminiException(
          'AI request failed for $feature.\n\nCheck your API key in lib/core/env.dart.\n\nError: $e');
    }
  }
}

class GeminiException implements Exception {
  final String message;
  const GeminiException(this.message);

  @override
  String toString() => message;
}