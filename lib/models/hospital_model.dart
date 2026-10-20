class HospitalRecommendation {
  final String name;
  final String type;
  final String whyRecommended;
  final String mapSearchQuery;

  const HospitalRecommendation({
    required this.name,
    required this.type,
    required this.whyRecommended,
    required this.mapSearchQuery,
  });
}

class HospitalFinderResult {
  final String triageAdvice;
  final List<HospitalRecommendation> facilities;
  final String rawResponse;

  const HospitalFinderResult({
    required this.triageAdvice,
    required this.facilities,
    required this.rawResponse,
  });

  factory HospitalFinderResult.fromGeminiResponse(String response) {
    String triage = '';
    final triageMatch = RegExp(
      r'TRIAGE_ADVICE:\s*([\s\S]*?)(?=FACILITIES:|$)',
      caseSensitive: false,
    ).firstMatch(response);
    if (triageMatch != null) {
      triage = triageMatch.group(1)?.trim() ?? '';
    }

    final List<HospitalRecommendation> parsedFacilities = [];
    final facilitiesMatch = RegExp(
      r'FACILITIES:\s*([\s\S]*?)$',
      caseSensitive: false,
    ).firstMatch(response);

    if (facilitiesMatch != null) {
      final block = facilitiesMatch.group(1)?.trim() ?? '';
      final lines = block
          .split('\n')
          .map((l) => l.replaceFirst(RegExp(r'^[•\-*\d.]\s*'), '').trim())
          .where((l) => l.isNotEmpty && l.contains('|'));

      for (final line in lines) {
        final parts = line.split('|').map((p) => p.trim()).toList();
        if (parts.length >= 3) {
          parsedFacilities.add(
            HospitalRecommendation(
              name: parts[0],
              type: parts[1],
              whyRecommended: parts[2],
              mapSearchQuery: parts.length >= 4 ? parts[3] : parts[0],
            ),
          );
        }
      }
    }

    return HospitalFinderResult(
      triageAdvice: triage.isNotEmpty
          ? triage
          : 'Proceed to the nearest emergency room immediately. Keep your JanRaksha QR ID ready.',
      facilities: parsedFacilities,
      rawResponse: response,
    );
  }
}