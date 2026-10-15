import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../services/gemini_service.dart';
import '../../services/ocr_service.dart';
import 'scan_extract_result_screen.dart';

class DocScannerScreen extends StatefulWidget {
  const DocScannerScreen({super.key});

  @override
  State<DocScannerScreen> createState() => _DocScannerScreenState();
}

class _DocScannerScreenState extends State<DocScannerScreen> {
  final _picker = ImagePicker();

  String? _imagePath;
  bool _isProcessing = false;
  _ProcessStep _step = _ProcessStep.idle;
  String? _error;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final image = await _picker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 2048,
        maxHeight: 2048,
      );
      if (image != null) {
        setState(() {
          _imagePath = image.path;
          _error = null;
          _step = _ProcessStep.idle;
        });
      }
    } catch (e) {
      setState(() =>
      _error = 'Could not access camera/gallery. Check permissions.');
    }
  }

  Future<void> _processDocument() async {
    if (_imagePath == null) return;

    final hasKey = await GeminiService.hasApiKey();
    if (!hasKey && mounted) {
      _showNoKeyDialog();
      return;
    }

    setState(() {
      _isProcessing = true;
      _error = null;
      _step = _ProcessStep.ocr;
    });

    try {
      // ── Step 1: OCR ──────────────────────────────────────
      final ocrResult = await OcrService.extractDetailed(_imagePath!);

      if (ocrResult.isEmpty) {
        setState(() {
          _error =
          'No text found in this image.\nTips: ensure good lighting, hold camera steady, and make sure the document text is in focus.';
          _isProcessing = false;
          _step = _ProcessStep.idle;
        });
        return;
      }

      // ── Step 2: Gemini AI Parse ───────────────────────────
      setState(() => _step = _ProcessStep.ai);

      final structured =
      await GeminiService.parseDocumentText(ocrResult.fullText);

      setState(() {
        _isProcessing = false;
        _step = _ProcessStep.done;
      });

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ScanExtractResultScreen(
              rawText: ocrResult.fullText,
              structured: structured,
              imagePath: _imagePath!,
            ),
          ),
        );
      }
    } on GeminiException catch (e) {
      setState(() {
        _error = e.userMessage;
        _isProcessing = false;
        _step = _ProcessStep.idle;
      });
    } catch (e) {
      setState(() {
        _error =
        'Processing failed: ${e.toString().length > 80 ? '${e.toString().substring(0, 80)}...' : e}';
        _isProcessing = false;
        _step = _ProcessStep.idle;
      });
    }
  }

  void _showNoKeyDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Gemini API Key Required'),
        content: const Text(
            'The AI Document Parser needs a Gemini API key. Set it up in Settings — it\'s free.'),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Later')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(
                  context, AppConstants.geminiSettingsRoute);
            },
            child: const Text('Set Up Now'),
          ),
        ],
      ),
    );
  }

  void _reset() {
    setState(() {
      _imagePath = null;
      _error = null;
      _step = _ProcessStep.idle;
      _isProcessing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Scanner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.pushNamed(
                context, AppConstants.geminiSettingsRoute),
            tooltip: 'Gemini Settings',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Feature Header ─────────────────────────────────
            _DocScannerHeader(),
            const SizedBox(height: 24),

            // ── Step Indicator ────────────────────────────────
            _StepIndicator(
              hasImage: _imagePath != null,
              step: _step,
            ),
            const SizedBox(height: 24),

            // ── Image Picker Buttons ──────────────────────────
            if (_imagePath == null) ...[
              Row(
                children: [
                  Expanded(
                    child: _SourceButton(
                      icon: Icons.camera_alt_outlined,
                      label: 'Camera',
                      subtitle: 'Take a new photo',
                      onTap: () => _pickImage(ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _SourceButton(
                      icon: Icons.photo_library_outlined,
                      label: 'Gallery',
                      subtitle: 'Choose existing photo',
                      onTap: () => _pickImage(ImageSource.gallery),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _TipsCard(),
            ],

            // ── Image Preview ─────────────────────────────────
            if (_imagePath != null) ...[
              Stack(
                children: [
                  // Image preview
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      File(_imagePath!),
                      width: double.infinity,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Container(
                        height: 200,
                        color: Colors.grey.shade200,
                        child: const Center(
                            child: Icon(Icons.broken_image, size: 48)),
                      ),
                    ),
                  ),
                  // Change / remove button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: _isProcessing ? null : _reset,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Source change options
              if (!_isProcessing)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt, size: 16),
                        label: const Text('Retake'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: AppTheme.primaryColor),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library,
                            size: 16),
                        label: const Text('Gallery'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: AppTheme.primaryColor),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 20),

              // ── Processing Steps Display ───────────────────
              if (_isProcessing) ...[
                _ProcessingCard(step: _step),
                const SizedBox(height: 20),
              ],

              // ── Error ──────────────────────────────────────
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppTheme.errorColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppTheme.errorColor, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(_error!,
                            style: const TextStyle(
                                color: AppTheme.errorColor,
                                fontSize: 13,
                                height: 1.4)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Extract Button ─────────────────────────────
              if (!_isProcessing)
                ElevatedButton.icon(
                  onPressed: _processDocument,
                  icon: const Icon(Icons.document_scanner),
                  label: const Text('Extract & Analyze with AI'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ── Feature Header ─────────────────────────────────────────────────────
class _DocScannerHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.teal.withValues(alpha: 0.08),
            AppTheme.primaryColor.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border:
        Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.teal.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.document_scanner_outlined,
                color: Colors.teal, size: 28),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Document Scanner',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppTheme.primaryColor)),
                SizedBox(height: 4),
                Text(
                  'Scan prescriptions, lab reports, or discharge summaries. AI extracts and imports data into your profile.',
                  style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step Indicator ─────────────────────────────────────────────────────
class _StepIndicator extends StatelessWidget {
  final bool hasImage;
  final _ProcessStep step;

  const _StepIndicator({required this.hasImage, required this.step});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StepDot(
            number: '1',
            label: 'Select',
            active: true,
            done: hasImage),
        _StepLine(active: hasImage),
        _StepDot(
            number: '2',
            label: 'Extract',
            active: hasImage,
            done: step == _ProcessStep.ai ||
                step == _ProcessStep.done),
        _StepLine(active: step == _ProcessStep.ai || step == _ProcessStep.done),
        _StepDot(
            number: '3',
            label: 'AI Parse',
            active: step == _ProcessStep.ai ||
                step == _ProcessStep.done,
            done: step == _ProcessStep.done),
        _StepLine(active: step == _ProcessStep.done),
        _StepDot(
            number: '4',
            label: 'Import',
            active: step == _ProcessStep.done,
            done: false),
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  final String number, label;
  final bool active, done;

  const _StepDot({
    required this.number,
    required this.label,
    required this.active,
    required this.done,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: done
                ? AppTheme.successColor
                : active
                ? AppTheme.primaryColor
                : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: done
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : Text(number,
                style: TextStyle(
                    color: active ? Colors.white : Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                fontSize: 10,
                color: active
                    ? AppTheme.primaryColor
                    : Colors.grey,
                fontWeight: active
                    ? FontWeight.w600
                    : FontWeight.normal)),
      ],
    );
  }
}

class _StepLine extends StatelessWidget {
  final bool active;
  const _StepLine({required this.active});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 20),
        color: active ? AppTheme.primaryColor : Colors.grey.shade300,
      ),
    );
  }
}

// ── Source Button ──────────────────────────────────────────────────────
class _SourceButton extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final VoidCallback onTap;

  const _SourceButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppTheme.primaryColor.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.primaryColor, size: 28),
            ),
            const SizedBox(height: 10),
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }
}

// ── Processing Card ────────────────────────────────────────────────────
class _ProcessingCard extends StatelessWidget {
  final _ProcessStep step;
  const _ProcessingCard({required this.step});

  @override
  Widget build(BuildContext context) {
    final isOcr = step == _ProcessStep.ocr;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
                strokeWidth: 2.5, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isOcr ? 'Step 2: Reading text (OCR)...' : 'Step 3: AI parsing data...',
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                    fontSize: 13),
              ),
              Text(
                isOcr
                    ? 'ML Kit scanning on-device — no internet needed'
                    : 'Gemini extracting medical fields...',
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Tips Card ──────────────────────────────────────────────────────────
class _TipsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border:
        Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.amber, size: 18),
              SizedBox(width: 8),
              Text('Tips for best results',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.amber,
                      fontSize: 13)),
            ],
          ),
          SizedBox(height: 8),
          _Tip('Good lighting — no shadows on the document'),
          _Tip('Hold camera parallel to document, not at an angle'),
          _Tip('Ensure all text is within the frame'),
          _Tip('Works with printed text; handwriting may not be recognized'),
          _Tip('Supported: prescriptions, lab reports, discharge summaries'),
        ],
      ),
    );
  }
}

class _Tip extends StatelessWidget {
  final String text;
  const _Tip(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ',
              style: TextStyle(color: Colors.amber, fontSize: 12)),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textPrimary,
                    height: 1.4)),
          ),
        ],
      ),
    );
  }
}

enum _ProcessStep { idle, ocr, ai, done }
