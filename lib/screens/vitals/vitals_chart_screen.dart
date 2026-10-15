import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/vitals_model.dart';
import '../../providers/vitals_provider.dart';

class VitalsChartScreen extends StatelessWidget {
  const VitalsChartScreen({super.key});

  List<String> _dateLabels(List<VitalsEntry> sorted) {
    return sorted.map((e) => '${e.timestamp.day}/${e.timestamp.month}').toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VitalsProvider>();
    // Oldest first for chronological left-to-right graphing
    final sortedEntries = provider.entries.reversed.toList();
    final labels = _dateLabels(sortedEntries);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Vitals Trends & AI'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Heart Rate'),
              Tab(text: 'Blood Pressure'),
              Tab(text: 'Glucose'),
              Tab(text: 'Weight'),
            ],
          ),
        ),
        body: sortedEntries.length < 2
            ? const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              'Log at least 2 vitals readings to view trend charts and unlock Gemini AI analysis.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
        )
            : Column(
          children: [
            SizedBox(
              height: 280,
              child: TabBarView(
                children: [
                  _SingleLineChart(
                    spots: sortedEntries
                        .asMap()
                        .entries
                        .map((e) => FlSpot(
                        e.key.toDouble(), e.value.heartRate.toDouble()))
                        .toList(),
                    labels: labels,
                    color: Colors.redAccent,
                    unit: 'bpm',
                  ),
                  _BPLineChart(
                    systolicSpots: sortedEntries
                        .asMap()
                        .entries
                        .map((e) => FlSpot(e.key.toDouble(),
                        e.value.systolicBP.toDouble()))
                        .toList(),
                    diastolicSpots: sortedEntries
                        .asMap()
                        .entries
                        .map((e) => FlSpot(e.key.toDouble(),
                        e.value.diastolicBP.toDouble()))
                        .toList(),
                    labels: labels,
                  ),
                  _SingleLineChart(
                    spots: sortedEntries
                        .asMap()
                        .entries
                        .map((e) => FlSpot(
                        e.key.toDouble(), e.value.glucoseLevel))
                        .toList(),
                    labels: labels,
                    color: Colors.purple,
                    unit: 'mmol/L',
                  ),
                  _SingleLineChart(
                    spots: sortedEntries
                        .asMap()
                        .entries
                        .map((e) =>
                        FlSpot(e.key.toDouble(), e.value.weight))
                        .toList(),
                    labels: labels,
                    color: Colors.teal,
                    unit: 'kg',
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _AIAnalysisSection(provider: provider),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SingleLineChart extends StatelessWidget {
  final List<FlSpot> spots;
  final List<String> labels;
  final Color color;
  final String unit;

  const _SingleLineChart({
    required this.spots,
    required this.labels,
    required this.color,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 24, 16),
      child: LineChart(
        LineChartData(
          clipData: const FlClipData.all(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: Colors.grey.shade200, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= labels.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(labels[index],
                        style: const TextStyle(fontSize: 10)),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey.shade300),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: color,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: color.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BPLineChart extends StatelessWidget {
  final List<FlSpot> systolicSpots;
  final List<FlSpot> diastolicSpots;
  final List<String> labels;

  const _BPLineChart({
    required this.systolicSpots,
    required this.diastolicSpots,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 24, 16),
      child: LineChart(
        LineChartData(
          clipData: const FlClipData.all(),
          gridData: FlGridData(
            show: true,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: Colors.grey.shade200, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= labels.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(labels[index],
                        style: const TextStyle(fontSize: 10)),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey.shade300),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: systolicSpots,
              isCurved: true,
              color: Colors.blue,
              barWidth: 3,
              dotData: const FlDotData(show: true),
            ),
            LineChartBarData(
              spots: diastolicSpots,
              isCurved: true,
              color: Colors.lightBlueAccent,
              barWidth: 2.5,
              dotData: const FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
  }
}

class _AIAnalysisSection extends StatelessWidget {
  final VitalsProvider provider;

  const _AIAnalysisSection({required this.provider});

  @override
  Widget build(BuildContext context) {
    final analysis = provider.lastAnalysis;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: provider.isAnalyzing ? null : () => provider.analyzeWithAI(),
          icon: provider.isAnalyzing
              ? const SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Icon(Icons.auto_awesome),
          label: Text(
              provider.isAnalyzing ? 'Analyzing with Gemini...' : 'Analyze Trends with AI'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        if (provider.error != null) ...[
          const SizedBox(height: 12),
          Text(
            provider.error!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ],
        if (analysis != null) ...[
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: analysis.hasAnomaly ? Colors.redAccent : Colors.green,
                width: 1.2,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        analysis.hasAnomaly
                            ? Icons.warning_amber_rounded
                            : Icons.check_circle_outline,
                        color:
                        analysis.hasAnomaly ? Colors.redAccent : Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        analysis.hasAnomaly
                            ? 'Anomaly Detected in Trends'
                            : 'Vitals Trends Look Stable',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Trend Summary',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(analysis.trendSummary),
                  if (analysis.concerningFindings.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Concerning Findings',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    ...analysis.concerningFindings.map(
                          (f) => Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Expanded(child: Text(f)),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  const Text(
                    'Recommendation',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(analysis.recommendation),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}