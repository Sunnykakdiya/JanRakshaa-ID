import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/loading_button.dart';
import '../../widgets/tag_input_field.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Basic Info controllers
  final _phoneCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();

  // Emergency Contact controllers
  final _ecNameCtrl = TextEditingController();
  final _ecPhoneCtrl = TextEditingController();
  final _ecRelationCtrl = TextEditingController();

  // Dropdown values
  String? _bloodGroup;
  String? _gender;

  // Tag lists
  List<String> _allergies = [];
  List<String> _medications = [];
  List<String> _conditions = [];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _prefillFields();
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _dobCtrl.dispose();
    _ecNameCtrl.dispose();
    _ecPhoneCtrl.dispose();
    _ecRelationCtrl.dispose();
    super.dispose();
  }

  void _prefillFields() {
    final user = context.read<AuthProvider>().userModel;
    if (user == null) return;

    _phoneCtrl.text = user.phone;
    _dobCtrl.text = user.dateOfBirth;
    _bloodGroup =
    user.bloodGroup.isEmpty ? null : user.bloodGroup;
    _gender = user.gender.isEmpty ? null : user.gender;
    _allergies = List.from(user.allergies);
    _medications = List.from(user.medications);
    _conditions = List.from(user.conditions);
    _ecNameCtrl.text = user.emergencyContactName;
    _ecPhoneCtrl.text = user.emergencyContactPhone;
    _ecRelationCtrl.text = user.emergencyContactRelation;
  }

  Future<void> _pickDOB() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25),
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme:
          const ColorScheme.light(primary: AppTheme.primaryColor),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _dobCtrl.text =
        '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final current = authProvider.userModel;
    if (current == null) return;

    setState(() => _isSaving = true);

    final updated = current.copyWith(
      phone: _phoneCtrl.text.trim(),
      dateOfBirth: _dobCtrl.text.trim(),
      bloodGroup: _bloodGroup ?? '',
      gender: _gender ?? '',
      allergies: _allergies,
      medications: _medications,
      conditions: _conditions,
      emergencyContactName: _ecNameCtrl.text.trim(),
      emergencyContactPhone: _ecPhoneCtrl.text.trim(),
      emergencyContactRelation: _ecRelationCtrl.text.trim(),
    );

    await authProvider.updateProfile(updated);

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Profile updated successfully!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── SECTION 1: Basic Info ──────────────────────
              const _SectionHeader(
                  icon: Icons.person_outline,
                  title: 'Basic Information'),
              const SizedBox(height: 14),

              CustomTextField(
                label: 'Phone Number',
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_outlined,
              ),
              const SizedBox(height: 14),

              CustomTextField(
                label: 'Date of Birth',
                controller: _dobCtrl,
                prefixIcon: Icons.calendar_today_outlined,
                readOnly: true,
                onTap: _pickDOB,
                suffixWidget: const Icon(
                    Icons.arrow_drop_down,
                    color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 14),

              // Gender Dropdown
              DropdownButtonFormField<String>(
                initialValue: _gender,
                decoration: InputDecoration(
                  labelText: 'Gender',
                  prefixIcon: const Icon(
                      Icons.wc_outlined, size: 20),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                      const BorderSide(color: Color(0xFFE5E7EB))),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                      const BorderSide(color: Color(0xFFE5E7EB))),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppTheme.primaryColor, width: 2)),
                ),
                items: AppConstants.genders
                    .map((g) => DropdownMenuItem(
                    value: g, child: Text(g)))
                    .toList(),
                onChanged: (v) => setState(() => _gender = v),
              ),

              const SizedBox(height: 28),

              // ── SECTION 2: Medical Info ────────────────────
              const _SectionHeader(
                  icon: Icons.medical_information_outlined,
                  title: 'Medical Information'),
              const SizedBox(height: 14),

              // Blood Group Dropdown
              DropdownButtonFormField<String>(
                initialValue: _bloodGroup,
                decoration: InputDecoration(
                  labelText: 'Blood Group *',
                  prefixIcon:
                  const Icon(Icons.bloodtype_outlined, size: 20),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                      const BorderSide(color: Color(0xFFE5E7EB))),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                      const BorderSide(color: Color(0xFFE5E7EB))),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppTheme.primaryColor, width: 2)),
                ),
                hint: const Text('Select blood group'),
                validator: (v) =>
                v == null ? 'Blood group is important for emergencies' : null,
                items: AppConstants.bloodGroups
                    .map((bg) => DropdownMenuItem(
                    value: bg, child: Text(bg)))
                    .toList(),
                onChanged: (v) => setState(() => _bloodGroup = v),
              ),
              const SizedBox(height: 20),

              TagInputField(
                label: '⚠️ Allergies',
                initialTags: _allergies,
                hint: 'e.g. Penicillin, Peanuts ...',
                color: Colors.orange,
                onChanged: (tags) => setState(() => _allergies = tags),
              ),
              const SizedBox(height: 20),

              TagInputField(
                label: '💊 Current Medications',
                initialTags: _medications,
                hint: 'e.g. Metformin 500mg ...',
                color: AppTheme.primaryColor,
                onChanged: (tags) =>
                    setState(() => _medications = tags),
              ),
              const SizedBox(height: 20),

              TagInputField(
                label: '🏥 Medical Conditions',
                initialTags: _conditions,
                hint: 'e.g. Type 2 Diabetes, Asthma ...',
                color: Colors.purple,
                onChanged: (tags) =>
                    setState(() => _conditions = tags),
              ),

              const SizedBox(height: 28),

              // ── SECTION 3: Emergency Contact ───────────────
              const _SectionHeader(
                  icon: Icons.emergency_outlined,
                  title: 'Emergency Contact'),
              const SizedBox(height: 14),

              CustomTextField(
                label: 'Contact Name *',
                controller: _ecNameCtrl,
                prefixIcon: Icons.person_pin_outlined,
                validator: (v) =>
                (v == null || v.isEmpty) ? 'Emergency contact name is required' : null,
              ),
              const SizedBox(height: 14),

              CustomTextField(
                label: 'Contact Phone *',
                controller: _ecPhoneCtrl,
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.call_outlined,
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Emergency contact phone is required';
                  }
                  if (v.length < 10) return 'Enter a valid phone number';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              CustomTextField(
                label: 'Relationship',
                controller: _ecRelationCtrl,
                prefixIcon: Icons.group_outlined,
                hint: 'e.g. Father, Mother, Spouse',
              ),

              const SizedBox(height: 32),

              // ── Save Button ────────────────────────────────
              LoadingButton(
                text: 'Save Profile',
                isLoading: _isSaving,
                onPressed: _save,
                icon: Icons.save_outlined,
              ),
              const SizedBox(height: 16),

              Center(
                child: Text(
                  'This data is stored securely in Firestore\nand encoded in your QR for offline access.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 11),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 20),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 16,
              color: AppTheme.primaryColor,
            )),
      ],
    );
  }
}