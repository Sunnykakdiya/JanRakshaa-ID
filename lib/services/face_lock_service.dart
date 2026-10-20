import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceLivenessResult {
  final bool isVerified;
  final double leftEyeOpen;
  final double rightEyeOpen;
  final double headAngleY;
  final String message;

  const FaceLivenessResult({
    required this.isVerified,
    this.leftEyeOpen = 0.0,
    this.rightEyeOpen = 0.0,
    this.headAngleY = 0.0,
    required this.message,
  });
}

class FaceLockService {
  static final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true, // Required for eye open probability
      enableLandmarks: true,
      enableTracking: false,
      minFaceSize: 0.25,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

  /// Analyzes an image file for a single live face with both eyes open.
  static Future<FaceLivenessResult> verifyLivenessFromFile(
      String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final List<Face> faces = await _detector.processImage(inputImage);

      if (faces.isEmpty) {
        return const FaceLivenessResult(
          isVerified: false,
          message:
          'No face detected. Ensure your face is clearly visible in good lighting.',
        );
      }

      if (faces.length > 1) {
        return const FaceLivenessResult(
          isVerified: false,
          message:
          'Multiple faces detected. Only one person should be in the frame.',
        );
      }

      final face = faces.first;
      final leftEye = face.leftEyeOpenProbability ?? -1.0;
      final rightEye = face.rightEyeOpenProbability ?? -1.0;
      final headY = (face.headEulerAngleY ?? 0.0).abs();

      // Ensure the user is looking straight at the camera
      if (headY > 25.0) {
        return FaceLivenessResult(
          isVerified: false,
          leftEyeOpen: leftEye > 0 ? leftEye : 0.0,
          rightEyeOpen: rightEye > 0 ? rightEye : 0.0,
          headAngleY: headY,
          message: 'Please look straight at the camera.',
        );
      }

      // Check liveness: both eyes must be clearly open (> 75% probability)
      if (leftEye < 0.75 || rightEye < 0.75) {
        return FaceLivenessResult(
          isVerified: false,
          leftEyeOpen: leftEye > 0 ? leftEye : 0.0,
          rightEyeOpen: rightEye > 0 ? rightEye : 0.0,
          headAngleY: headY,
          message:
          'Liveness check failed: Please keep both eyes wide open while scanning.',
        );
      }

      return FaceLivenessResult(
        isVerified: true,
        leftEyeOpen: leftEye,
        rightEyeOpen: rightEye,
        headAngleY: headY,
        message: 'Liveness verified! Face biometric authenticated.',
      );
    } catch (e) {
      return const FaceLivenessResult(
        isVerified: false,
        message: 'Failed to process face image. Please try again.',
      );
    }
  }

  static Future<void> dispose() async {
    await _detector.close();
  }
}