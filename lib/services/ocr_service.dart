import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Wraps ML Kit Text Recognition for medical document OCR.
/// Runs 100% on-device — no API calls, no cost, works offline.
/// Supports printed text (Latin script) in prescriptions, reports, etc.
class OcrService {
  // ── Extract text from a file path (image_picker result) ──────────────
  static Future<String> extractFromPath(String imagePath) async {
    final recognizer =
    TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognized = await recognizer.processImage(inputImage);
      return recognized.text;
    } finally {
      await recognizer.close();
    }
  }

  // ── Extract with block metadata (for confidence filtering) ───────────
  static Future<OcrResult> extractDetailed(String imagePath) async {
    final recognizer =
    TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognized = await recognizer.processImage(inputImage);

      final blocks = recognized.blocks
          .map((b) => OcrBlock(
        text: b.text,
        lines: b.lines.map((l) => l.text).toList(),
      ))
          .toList();

      return OcrResult(
        fullText: recognized.text,
        blocks: blocks,
        blockCount: recognized.blocks.length,
        lineCount: recognized.blocks
            .fold(0, (sum, b) => sum + b.lines.length),
      );
    } finally {
      await recognizer.close();
    }
  }
}

class OcrResult {
  final String fullText;
  final List<OcrBlock> blocks;
  final int blockCount;
  final int lineCount;

  const OcrResult({
    required this.fullText,
    required this.blocks,
    required this.blockCount,
    required this.lineCount,
  });

  bool get isEmpty => fullText.trim().isEmpty;
  int get wordCount => fullText.split(RegExp(r'\s+')).length;
}

class OcrBlock {
  final String text;
  final List<String> lines;
  const OcrBlock({required this.text, required this.lines});
}
