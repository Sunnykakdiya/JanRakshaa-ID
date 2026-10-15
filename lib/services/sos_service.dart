import 'package:geolocator/geolocator.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants.dart';
import '../models/user_model.dart';

class SosService {
  static const List<String> triggerWords = [
    'help',
    'emergency',
    'sos',
    'call ambulance',
    'save me',
    'accident',
  ];

  /// Checks if spoken text contains any emergency trigger phrase.
  static String? detectTriggerWord(String spokenText) {
    final lower = spokenText.toLowerCase();
    for (final word in triggerWords) {
      if (lower.contains(word)) {
        return word;
      }
    }
    return null;
  }

  /// Gets current GPS coordinates with permission handling.
  static Future<Position?> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// Generates an urgent, concise SMS payload using Gemini AI (with offline fallback).
  static Future<String> generateSosMessage({
    required UserModel? user,
    required Position? position,
    String? spokenContext,
  }) async {
    final String mapLink = position != null
        ? 'https://maps.google.com/?q=${position.latitude},${position.longitude}'
        : 'Location unavailable';

    final String name =
    (user != null && user.name.isNotEmpty) ? user.name : 'A JanRaksha User';
    final String blood =
    (user != null && user.bloodGroup.isNotEmpty) ? user.bloodGroup : 'N/A';
    final String allergies = (user != null && user.allergies.isNotEmpty)
        ? user.allergies.join(', ')
        : 'None';
    final String conditions = (user != null && user.conditions.isNotEmpty)
        ? user.conditions.join(', ')
        : 'None';

    // Default fallback message if offline or API key not set
    final String fallbackMessage =
        '🚨 EMERGENCY SOS from $name!\n'
        'I need immediate medical assistance.\n'
        '📍 GPS Location: $mapLink\n'
        '🩸 Blood Group: $blood\n'
        '⚠️ Allergies: $allergies\n'
        '🏥 Conditions: $conditions';

    try {
      final prefs = await SharedPreferences.getInstance();
      final apiKey = prefs.getString(AppConstants.geminiApiKeyPref) ?? '';
      if (apiKey.isEmpty) return fallbackMessage;

      final model = GenerativeModel(
        model: AppConstants.geminiModel,
        apiKey: apiKey,
      );

      final prompt = '''
Generate an urgent, clear emergency SOS text message (under 65 words) to be sent to an emergency contact.
Include all critical details below clearly:
- Patient Name: $name
- Blood Group: $blood
- Allergies: $allergies
- Medical Conditions: $conditions
- Voice Trigger / Spoken Context: ${spokenContext ?? 'Emergency SOS triggered'}
- Exact Google Maps Link: $mapLink

Do NOT use markdown bolding (**). Keep it plain text with emojis for instant readability.
''';

      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text?.trim();
      if (text != null && text.isNotEmpty) {
        return text;
      }
      return fallbackMessage;
    } catch (_) {
      return fallbackMessage;
    }
  }

  /// Opens the SMS app pre-filled with the emergency contact and AI SOS message.
  static Future<bool> sendEmergencySms({
    required String phone,
    required String message,
  }) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: cleanPhone,
      queryParameters: <String, String>{'body': message},
    );
    if (await canLaunchUrl(smsUri)) {
      return await launchUrl(smsUri);
    }
    return false;
  }

  /// Initiates a phone call to the emergency contact or 108/112 ambulance.
  static Future<bool> callNumber(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri telUri = Uri(scheme: 'tel', path: cleanPhone);
    if (await canLaunchUrl(telUri)) {
      return await launchUrl(telUri);
    }
    return false;
  }
}