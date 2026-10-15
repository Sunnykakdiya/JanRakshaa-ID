import 'package:flutter/material.dart';
import '../models/vitals_model.dart';

class VitalsSummaryCard extends StatelessWidget {
  final VitalsEntry latest;
  final VitalsEntry? previous;

  const VitalsSummaryCard({
    super.key,
    required this.latest,
    this.previous,
  });

  Color _badgeColor(String level) {
    switch (level) {
      case 'danger':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  IconData _trendIcon(num current, num? prev) {
    if (prev == null) return Icons.remove;
    if (current > prev) return Icons.trending_up;
    if (current < prev) return Icons.trending_down;
    return Icons.trending_flat;
  }

  @override
  Widget build(BuildContext context) {
    final badgeColor = _badgeColor(latest.alertLevel);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Latest Reading Summary',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: badgeColor),
                  ),
                  child: Text(
                    latest.alertLevel.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: badgeColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                _buildTile(
                  icon: Icons.favorite,
                  color: Colors.redAccent,
                  label: 'Heart Rate',
                  value: '${latest.heartRate} bpm',
                  trend: _trendIcon(latest.heartRate, previous?.heartRate),
                ),
                _buildTile(
                  icon: Icons.speed,
                  color: Colors.blueAccent,
                  label: 'Blood Pressure',
                  value: '${latest.systolicBP}/${latest.diastolicBP}',
                  trend: _trendIcon(latest.systolicBP, previous?.systolicBP),
                ),
                _buildTile(
                  icon: Icons.water_drop,
                  color: Colors.purpleAccent,
                  label: 'Glucose',
                  value: '${latest.glucoseLevel.toStringAsFixed(1)} mmol/L',
                  trend: _trendIcon(latest.glucoseLevel, previous?.glucoseLevel),
                ),
                _buildTile(
                  icon: Icons.monitor_weight,
                  color: Colors.teal,
                  label: 'Weight',
                  value: '${latest.weight.toStringAsFixed(1)} kg',
                  trend: _trendIcon(latest.weight, previous?.weight),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
    required IconData trend,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        value,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(trend, size: 14, color: Colors.grey.shade600),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}