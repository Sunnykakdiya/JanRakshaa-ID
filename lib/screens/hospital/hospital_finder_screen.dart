import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/hospital_provider.dart';
import '../../services/hospital_service.dart';

class HospitalFinderScreen extends StatefulWidget {
  const HospitalFinderScreen({super.key});

  @override
  State<HospitalFinderScreen> createState() => _HospitalFinderScreenState();
}

class _HospitalFinderScreenState extends State<HospitalFinderScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HospitalProvider>().refreshLocation();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HospitalProvider>();
    final user = context.watch<UserProvider>().user ??
        context.watch<AuthProvider>().userModel;
    final pos = provider.currentPosition;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Emergency Hospital Finder'),
        backgroundColor: AppTheme.successColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'Refresh GPS',
            onPressed: provider.isLocating ? null : provider.refreshLocation,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── GPS Location Status Banner ─────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: pos != null
                      ? AppTheme.successColor.withValues(alpha: 0.4)
                      : Colors.orange.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: (pos != null
                        ? AppTheme.successColor
                        : Colors.orange)
                        .withValues(alpha: 0.12),
                    child: provider.isLocating
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : Icon(
                      pos != null
                          ? Icons.gps_fixed
                          : Icons.location_searching,
                      color: pos != null
                          ? AppTheme.successColor
                          : Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pos != null
                              ? 'Live GPS Coordinates Locked'
                              : 'Acquiring GPS Coordinates...',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          pos != null
                              ? 'Lat: ${pos.latitude.toStringAsFixed(4)}, Lng: ${pos.longitude.toStringAsFixed(4)}'
                              : 'Tap the location icon in the top bar to retry',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => HospitalService.openMapsSearch(
                      query: '${provider.selectedType} hospital near me',
                      position: pos,
                    ),
                    icon: const Icon(Icons.map_outlined, size: 18),
                    label: const Text('Maps'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Emergency Specialty Selector ───────────────────────
            const Text(
              'Select Emergency Type',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: HospitalService.emergencyTypes.map((type) {
                final selected = provider.selectedType == type;
                return ChoiceChip(
                  label: Text(type),
                  selected: selected,
                  selectedColor: AppTheme.successColor.withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color:
                    selected ? AppTheme.successColor : AppTheme.textPrimary,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  onSelected: (_) => provider.setEmergencyType(type),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // ── Find Facilities with Gemini AI Button ──────────────
            ElevatedButton.icon(
              onPressed: provider.isSearching
                  ? null
                  : () => provider.findHospitals(user: user),
              icon: provider.isSearching
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
                  : const Icon(Icons.local_hospital),
              label: Text(
                provider.isSearching
                    ? 'Locating Best Facilities with AI...'
                    : 'Find Nearest Emergency Hospitals',
                style:
                const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),

            // ── Error Banner ───────────────────────────────────────
            if (provider.error != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  provider.error!,
                  style: const TextStyle(
                      color: AppTheme.errorColor, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            // ── Results Section ────────────────────────────────────
            if (provider.result != null) ...[
              const SizedBox(height: 22),

              // Pre-Arrival Triage Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border:
                  Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.medical_information,
                            color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'AI Pre-Arrival Triage Advice',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.deepOrange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      provider.result!.triageAdvice,
                      style: const TextStyle(fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              const Text(
                'Recommended Facilities Near You',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              ...provider.result!.facilities.map(
                    (fac) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.successColor
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.local_hospital,
                                  color: AppTheme.successColor),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    fac.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    fac.type,
                                    style: const TextStyle(
                                      color: AppTheme.successColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          fac.whyRecommended,
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => HospitalService.openMapsSearch(
                              query: fac.mapSearchQuery,
                              position: pos,
                            ),
                            icon: const Icon(Icons.directions, size: 18),
                            label: const Text('Open in Google Maps'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primaryColor,
                              side: const BorderSide(
                                  color: AppTheme.primaryColor),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),
            // ── Direct 108 Ambulance Call Button ───────────────────
            OutlinedButton.icon(
              onPressed: () => HospitalService.callEmergencyNumber('108'),
              icon: const Icon(Icons.emergency, color: AppTheme.errorColor),
              label: const Text(
                'Call 108 Emergency Ambulance',
                style: TextStyle(
                    color: AppTheme.errorColor, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.errorColor),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}