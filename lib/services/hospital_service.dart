import 'package:geolocator/geolocator.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants.dart';
import '../models/hospital_model.dart';
import '../models/user_model.dart';

class HospitalService {
  static const List<String> emergencyTypes = [
    'General Emergency',
    'Cardiac / Heart Attack',
    'Trauma / Road Accident',
    'Stroke / Neurology',
    'Respiratory / Asthma',
    'Maternity / OB-GYN',
  ];

  /// Fetches live GPS coordinates with permission checks.
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

  /// Queries Gemini AI for nearby hospitals & emergency triage guidance based on GPS + specialty.
  static Future<HospitalFinderResult> findEmergencyFacilities({
    required Position? position,
    required String emergencyType,
    UserModel? user,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString(AppConstants.geminiApiKeyPref) ?? '';

    if (apiKey.isEmpty) {
      throw Exception('Please configure your Gemini API key in Settings first.');
    }

    final coordsText = position != null
        ? 'Latitude: ${position.latitude.toStringAsFixed(4)}, Longitude: ${position.longitude.toStringAsFixed(4)}'
        : 'Coordinates unavailable (provide general multi-specialty hospital categories)';

    final profileContext = user != null
        ? 'Blood Group: ${user.bloodGroup}, Allergies: ${user.allergies.join(", ")}, Conditions: ${user.conditions.join(", ")}'
        : 'No profile context';

    final prompt = '''
You are an emergency medical dispatch AI for the JanRaksha app.
A user needs immediate hospital recommendations based on:
- Emergency Type: $emergencyType
- Current GPS Location: $coordsText
- Patient Profile: $profileContext

Identify the city/region from the GPS coordinates and list 3 to 4 real, well-known hospitals or emergency medical centers in or near that area suited for "$emergencyType" (or top emergency facility types if exact local names are uncertain).

Respond STRICTLY in this exact format:

TRIAGE_ADVICE:
[2-3 sentences of critical pre-arrival instructions for $emergencyType considering the patient profile]

FACILITIES:
- [Hospital Name] | [Facility Specialty/Type] | [1 sentence why it fits this emergency] | [Google Maps search query]
- [Hospital Name] | [Facility Specialty/Type] | [1 sentence why it fits this emergency] | [Google Maps search query]
- [Hospital Name] | [Facility Specialty/Type] | [1 sentence why it fits this emergency] | [Google Maps search query]
''';

    final model = GenerativeModel(
      model: AppConstants.geminiModel,
      apiKey: apiKey,
    );

    final response = await model.generateContent([Content.text(prompt)]);
    final text = response.text;

    if (text == null || text.isEmpty) {
      throw Exception('Received an empty response from Gemini AI.');
    }

    return HospitalFinderResult.fromGeminiResponse(text);
  }

  /// Opens Google Maps directly searching for the facility near the user's GPS coordinates.
  static Future<void> openMapsSearch({
    required String query,
    Position? position,
  }) async {
    final encodedQuery = Uri.encodeComponent(query);
    final String url = position != null
        ? 'https://www.google.com/maps/search/?api=1&query=$encodedQuery&center=${position.latitude},${position.longitude}'
        : 'https://www.google.com/maps/search/?api=1&query=$encodedQuery';

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Dials an emergency number (e.g., 108 Ambulance).
  static Future<void> callEmergencyNumber(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}