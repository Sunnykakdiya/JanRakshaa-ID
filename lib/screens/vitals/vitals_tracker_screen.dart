import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants.dart';
import '../../models/vitals_model.dart';
import '../../providers/vitals_provider.dart';
import '../../services/vitals_service.dart';
import '../../widgets/vitals_card.dart';

class VitalsTrackerScreen extends StatefulWidget {
  const VitalsTrackerScreen({super.key});

  @override
  State<VitalsTrackerScreen> createState() => _VitalsTrackerScreenState();
}

class _VitalsTrackerScreenState extends State<VitalsTrackerScreen> {
  void _openLogVitalsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _LogVitalsBottomSheet(),
    );
  }

  Color _statusColor(String level) {
    switch (level) {
      case 'danger':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VitalsProvider>();
    final entries = provider.entries;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vitals AI Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.show_chart),
            tooltip: 'View Charts & AI Analysis',
            onPressed: () {
              Navigator.pushNamed(context, AppConstants.vitalsChartRoute);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openLogVitalsSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Log Reading'),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : entries.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.monitor_heart_outlined,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text(
              'No vitals logged yet.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _openLogVitalsSheet(context),
              icon: const Icon(Icons.add),
              label: const Text('Log Your First Reading'),
            ),
          ],
        ),
      )
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          VitalsSummaryCard(
            latest: entries.first,
            previous: entries.length > 1 ? entries[1] : null,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent History',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: () => Navigator.pushNamed(
                    context, AppConstants.vitalsChartRoute),
                icon: const Icon(Icons.analytics_outlined, size: 18),
                label: const Text('Charts & AI'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...entries.take(10).map((entry) {
            final d = entry.timestamp;
            final dateStr =
                '${d.day}/${d.month}/${d.year} • ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
            final color = _statusColor(entry.alertLevel);

            return Dismissible(
              key: ValueKey(entry.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              onDismissed: (_) {
                final uid =
                    FirebaseAuth.instance.currentUser?.uid ?? '';
                if (uid.isNotEmpty) {
                  provider.deleteEntry(uid, entry.id);
                }
              },
              child: Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color.withOpacity(0.15),
                    child: Icon(Icons.favorite, color: color, size: 20),
                  ),
                  title: Text(
                    'HR: ${entry.heartRate} bpm  |  BP: ${entry.systolicBP}/${entry.diastolicBP}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: Text(
                    'Glucose: ${entry.glucoseLevel} mmol/L • Weight: ${entry.weight} kg\n$dateStr',
                    style: const TextStyle(fontSize: 12),
                  ),
                  isThreeLine: true,
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      entry.alertLevel.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 60),
        ],
      ),
    );
  }
}

class _LogVitalsBottomSheet extends StatefulWidget {
  const _LogVitalsBottomSheet();

  @override
  State<_LogVitalsBottomSheet> createState() => _LogVitalsBottomSheetState();
}

class _LogVitalsBottomSheetState extends State<_LogVitalsBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _hrCtrl = TextEditingController();
  final _sysCtrl = TextEditingController();
  final _diaCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _glucoseCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _hrCtrl.dispose();
    _sysCtrl.dispose();
    _diaCtrl.dispose();
    _weightCtrl.dispose();
    _glucoseCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _saving = true);

    final hr = int.parse(_hrCtrl.text.trim());
    final sys = int.parse(_sysCtrl.text.trim());
    final dia = int.parse(_diaCtrl.text.trim());
    final weight = double.parse(_weightCtrl.text.trim());
    final glucose = double.parse(_glucoseCtrl.text.trim());

    final alertLevel = VitalsThreshold.classify(
      heartRate: hr,
      systolicBP: sys,
      glucoseLevel: glucose,
    );

    final entry = VitalsEntry(
      id: '',
      userId: uid,
      heartRate: hr,
      systolicBP: sys,
      diastolicBP: dia,
      weight: weight,
      glucoseLevel: glucose,
      notes: _notesCtrl.text.trim(),
      timestamp: DateTime.now(),
      alertLevel: alertLevel,
    );

    final success = await context.read<VitalsProvider>().addVitals(entry);
    if (mounted) {
      setState(() => _saving = false);
      if (success) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Log New Vitals Reading',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _hrCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Heart Rate (bpm)',
                  prefixIcon: Icon(Icons.favorite_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                (v == null || int.tryParse(v) == null) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _sysCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Systolic BP',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || int.tryParse(v) == null)
                          ? 'Required'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _diaCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Diastolic BP',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || int.tryParse(v) == null)
                          ? 'Required'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _glucoseCtrl,
                      keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Glucose (mmol/L)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                      (v == null || double.tryParse(v) == null)
                          ? 'Required'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _weightCtrl,
                      keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Weight (kg)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                      (v == null || double.tryParse(v) == null)
                          ? 'Required'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _saving
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Text('Save Reading'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}