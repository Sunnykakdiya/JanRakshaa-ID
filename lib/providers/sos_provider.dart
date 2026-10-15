import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../models/user_model.dart';
import '../services/sos_service.dart';

enum SosState {
  idle,
  listening,
  countdown,
  generatingAlert,
  alertReady,
}

class SosProvider extends ChangeNotifier {
  final stt.SpeechToText _speech = stt.SpeechToText();

  SosState _state = SosState.idle;
  bool _speechAvailable = false;
  String _recognizedWords = '';
  String? _detectedTrigger;
  int _countdownSeconds = 5;
  Timer? _countdownTimer;

  Position? _currentPosition;
  String _sosMessage = '';
  String? _error;

  SosState get state => _state;
  bool get isListening => _state == SosState.listening;
  String get recognizedWords => _recognizedWords;
  String? get detectedTrigger => _detectedTrigger;
  int get countdownSeconds => _countdownSeconds;
  Position? get currentPosition => _currentPosition;
  String get sosMessage => _sosMessage;
  String? get error => _error;

  /// Initializes speech recognition and starts listening for trigger words.
  Future<void> startVoiceListening({required UserModel? user}) async {
    _error = null;
    _recognizedWords = '';
    _detectedTrigger = null;

    _speechAvailable = await _speech.initialize(
      onError: (err) {
        _error = 'Microphone error: ${err.errorMsg}';
        _state = SosState.idle;
        notifyListeners();
      },
    );

    if (!_speechAvailable) {
      _error = 'Speech recognition permission denied or unavailable.';
      notifyListeners();
      return;
    }

    _state = SosState.listening;
    notifyListeners();

    await _speech.listen(
      onResult: (result) {
        _recognizedWords = result.recognizedWords;
        notifyListeners();

        final trigger = SosService.detectTriggerWord(_recognizedWords);
        if (trigger != null && _state == SosState.listening) {
          _detectedTrigger = trigger.toUpperCase();
          stopVoiceListening();
          startSosCountdown(user: user, spokenContext: _recognizedWords);
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 5),
    );
  }

  Future<void> stopVoiceListening() async {
    await _speech.stop();
    if (_state == SosState.listening) {
      _state = SosState.idle;
      notifyListeners();
    }
  }

  /// Starts a 5-second countdown before dispatching the SOS alert.
  void startSosCountdown({required UserModel? user, String? spokenContext}) {
    _speech.stop();
    _state = SosState.countdown;
    _countdownSeconds = 5;
    _error = null;
    notifyListeners();

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds > 1) {
        _countdownSeconds--;
        notifyListeners();
      } else {
        timer.cancel();
        _prepareAndTriggerSos(user: user, spokenContext: spokenContext);
      }
    });
  }

  /// Cancels an active countdown or resets the SOS screen.
  void cancelSos() {
    _countdownTimer?.cancel();
    _speech.stop();
    _state = SosState.idle;
    _detectedTrigger = null;
    _error = null;
    notifyListeners();
  }

  /// Fetches GPS + generates the Gemini AI SOS message.
  Future<void> _prepareAndTriggerSos({
    required UserModel? user,
    String? spokenContext,
  }) async {
    _state = SosState.generatingAlert;
    notifyListeners();

    try {
      _currentPosition = await SosService.getCurrentLocation();
      _sosMessage = await SosService.generateSosMessage(
        user: user,
        position: _currentPosition,
        spokenContext: spokenContext,
      );
      _state = SosState.alertReady;
      notifyListeners();

      // Automatically open SMS dispatch if emergency contact phone exists
      if (user != null && user.emergencyContactPhone.isNotEmpty) {
        await SosService.sendEmergencySms(
          phone: user.emergencyContactPhone,
          message: _sosMessage,
        );
      }
    } catch (e) {
      _error = 'Failed to prepare SOS alert.';
      _state = SosState.idle;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _speech.stop();
    super.dispose();
  }
}