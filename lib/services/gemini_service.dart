import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../models/user_model.dart';

/// Central service for all Gemini AI features.
/// Phase 3: Symptom Checker, Drug Interaction, Emergency Brief
/// Phase 4: Document OCR Parser (parseDocumentText)
class GeminiService {

  // ── API Key Management ────────────────────────────────────────────────

  static Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.geminiApiKeyPref);
  }

  static Future<void> saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.geminiApiKeyPref, key.trim());
  }

  static Future<bool> hasApiKey() async {
    final key = await getApiKey();
    return key != null && key.isNotEmpty;
  }

  static Future<void> clearApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.geminiApiKeyPref);
  }

  // ── Core Generator ────────────────────────────────────────────────────

  static Future<GenerativeModel> _model() async {
    final key = await getApiKey();
    if (key == null || key.isEmpty) throw GeminiException.noKey();
    return GenerativeModel(
      model: AppConstants.geminiModel,
      apiKey: key,
      generationConfig:
      GenerationConfig(temperature: 0.4, maxOutputTokens: 600),
    );
  }

  static Future<String> _generate(String prompt) async {
    try {
      final model = await _model();
      final response =
      await model.generateContent([Content.text(prompt)]);
      return response.text?.trim() ?? 'No response received.';
    } on GeminiException {
      rethrow;
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('api key') || msg.contains('invalid')) {
        throw GeminiException.invalidKey();
      }
      if (msg.contains('quota') || msg.contains('429')) {
        throw GeminiException.rateLimit();
      }
      if (msg.contains('network') || msg.contains('socket')) {
        throw GeminiException.noNetwork();
      }
      throw GeminiException('AI error: $e');
    }
  }

  // ── Feature 1: Symptom Checker ────────────────────────────────────────

  static Future<String> checkSymptoms({
    required String symptoms,
    UserModel? user,
  }) async {
    final sb = StringBuffer();
    sb.writeln(
        'You are a helpful medical AI assistant inside an emergency app.');
    sb.writeln('A person reports these symptoms: "$symptoms"');

    if (user != null) {
      final hasCtx = user.bloodGroup.isNotEmpty ||
          user.allergies.isNotEmpty ||
          user.medications.isNotEmpty ||
          user.conditions.isNotEmpty;
      if (hasCtx) {
        sb.writeln('\nPatient profile context:');
        if (user.bloodGroup.isNotEmpty) sb.writeln('• Blood Group: ${user.bloodGroup}');
        if (user.allergies.isNotEmpty) sb.writeln('• Allergies: ${user.allergies.join(', ')}');
        if (user.medications.isNotEmpty) sb.writeln('• Medications: ${user.medications.join(', ')}');
        if (user.conditions.isNotEmpty) sb.writeln('• Conditions: ${user.conditions.join(', ')}');
      }
    }

    sb.writeln('''

Provide a structured analysis using EXACTLY this format:

POSSIBLE CAUSES:
• [cause 1]
• [cause 2]
• [cause 3 if applicable]

IMMEDIATE ACTIONS:
• [action 1]
• [action 2]
• [action 3]

EMERGENCY LEVEL: [🚨 SEEK EMERGENCY CARE NOW / ⚠️ SEE A DOCTOR TODAY / ✅ MONITOR AT HOME]

WHEN TO CALL EMERGENCY:
[One sentence about warning signs needing immediate 112/emergency call]

Keep total under 220 words.
End with exactly: "⚠️ This is not a medical diagnosis. Always consult a qualified doctor."''');

    return _generate(sb.toString());
  }

  // ── Feature 2: Drug Interaction Checker ───────────────────────────────

  static Future<String> checkDrugInteractions({
    required List<String> medications,
  }) async {
    if (medications.length < 2) {
      return 'Please add at least 2 medications to check interactions.';
    }

    final prompt = '''You are a clinical pharmacology AI assistant.

Check for drug interactions between:
${medications.map((m) => '• $m').join('\n')}

Use EXACTLY this format:

OVERALL RISK: [NONE / LOW / MODERATE / HIGH]

INTERACTIONS FOUND:
[For each pair that interacts: "Drug A + Drug B: [effect]"
If none: "No significant interactions found."]

RECOMMENDATIONS:
• [advice 1]
• [advice 2]

Keep total under 200 words.
End with exactly: "⚠️ Always confirm with your doctor or pharmacist before changing medications."''';

    return _generate(prompt);
  }

  // ── Feature 3: Emergency Brief Generator ─────────────────────────────

  static Future<String> generateEmergencyBrief({
    required UserModel user,
  }) async {
    final prompt = '''You are an emergency medical AI.
Generate a first-responder brief readable in 10 seconds.

Patient:
Name: ${user.name.isEmpty ? 'Unknown' : user.name}
Blood Group: ${user.bloodGroup.isEmpty ? 'Unknown' : user.bloodGroup}
DOB: ${user.dateOfBirth.isEmpty ? 'Unknown' : user.dateOfBirth}
Allergies: ${user.allergies.isEmpty ? 'None known' : user.allergies.join(', ')}
Medications: ${user.medications.isEmpty ? 'None' : user.medications.join(', ')}
Conditions: ${user.conditions.isEmpty ? 'None known' : user.conditions.join(', ')}
Emergency Contact: ${user.emergencyContactName} (${user.emergencyContactRelation}) — ${user.emergencyContactPhone}

Format: 4–6 bullet points, most critical first. Max 90 words. No disclaimers.''';

    return _generate(prompt);
  }

  // ── Feature 4: Document OCR Parser (Phase 4) ─────────────────────────
  /// Takes raw text from ML Kit OCR and extracts structured medical data.
  /// Returns a map with keys: blood_group, medications, allergies,
  /// conditions, doctor_name, hospital, date_of_report.

  static Future<Map<String, dynamic>> parseDocumentText(
      String rawText) async {
    final prompt = '''You are a medical document parser AI.

Extract medical information from this scanned document text and return it as valid JSON:

--- DOCUMENT TEXT START ---
$rawText
--- DOCUMENT TEXT END ---

Return ONLY a valid JSON object with these exact keys. Use empty string "" for missing text fields and empty array [] for missing list fields. Do NOT include any explanation or markdown — raw JSON only:

{
  "blood_group": "",
  "medications": [],
  "allergies": [],
  "conditions": [],
  "doctor_name": "",
  "hospital": "",
  "date_of_report": "",
  "patient_name": ""
}

Rules:
- medications: array of strings, each with name and dosage if visible (e.g. "Metformin 500mg")
- allergies: array of allergy strings
- conditions: array of diagnosis/condition strings  
- blood_group: string like "O+" or "AB-", empty if not found
- All other fields: plain text string, empty if not found''';

    try {
      final raw = await _generate(prompt);
      // Strip any markdown code fences Gemini might add
      final cleaned = raw
          .replaceAll(RegExp(r'```json\s*'), '')
          .replaceAll(RegExp(r'```\s*'), '')
          .trim();

      // Find the first { and last } to isolate the JSON
      final start = cleaned.indexOf('{');
      final end = cleaned.lastIndexOf('}');
      if (start == -1 || end == -1 || end <= start) {
        return _emptyDocResult();
      }

      final jsonStr = cleaned.substring(start, end + 1);
      final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
      return parsed;
    } catch (_) {
      return _emptyDocResult();
    }
  }

  static Map<String, dynamic> _emptyDocResult() => {
    'blood_group': '',
    'medications': <String>[],
    'allergies': <String>[],
    'conditions': <String>[],
    'doctor_name': '',
    'hospital': '',
    'date_of_report': '',
    'patient_name': '',
  };

  // ── API Key Validation ────────────────────────────────────────────────

  static Future<String?> testApiKey(String key) async {
    try {
      final trimmedKey = key.trim();

      if (trimmedKey.isEmpty) {
        return 'API key is empty.';
      }

      final model = GenerativeModel(
        model: AppConstants.geminiModel,
        apiKey: trimmedKey,
      );

      final response = await model.generateContent(
        [Content.text('Reply with exactly: OK')],
      );

      final text = response.text?.trim();

      if (text != null && text.isNotEmpty) {
        return null; // null means success
      }

      return 'Gemini returned an empty response.';
    } on InvalidApiKey {
      return 'Invalid API key. Please check your Gemini API key.';
    } on UnsupportedUserLocation {
      return 'Gemini API is not available in your current location.';
    } on ServerException catch (e) {
      return 'Gemini server error: $e';
    } on GenerativeAIException catch (e) {
      return 'Gemini API error: $e';
    } catch (e) {
      return 'Connection/test error: $e';
    }
  }
}

// ── Custom Exception ───────────────────────────────────────────────────

class GeminiException implements Exception {
  final String message;
  const GeminiException(this.message);

  factory GeminiException.noKey() =>
      const GeminiException('GEMINI_KEY_NOT_SET');
  factory GeminiException.invalidKey() =>
      const GeminiException('GEMINI_KEY_INVALID');
  factory GeminiException.rateLimit() =>
      const GeminiException('GEMINI_RATE_LIMIT');
  factory GeminiException.noNetwork() =>
      const GeminiException('GEMINI_NO_NETWORK');

  bool get isNoKey => message == 'GEMINI_KEY_NOT_SET';
  bool get isInvalidKey => message == 'GEMINI_KEY_INVALID';
  bool get isRateLimit => message == 'GEMINI_RATE_LIMIT';

  String get userMessage {
    if (isNoKey) return 'Gemini API key not set. Tap ⚙️ to add it.';
    if (isInvalidKey) return 'Invalid API key. Check Settings and re-enter it.';
    if (isRateLimit) return 'Free tier limit reached. Wait a moment and try again.';
    return 'Network error. Check your internet connection.';
  }
}
