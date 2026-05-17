import 'package:flutter_tts/flutter_tts.dart';
import '../models/drowsiness_state.dart';

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;
  DateTime? _lastSpokenTime;
  Duration _normalCooldown = const Duration(seconds: 8);
  Duration _dangerCooldown = const Duration(seconds: 3);

  TtsService() {
    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.awaitSpeakCompletion(true);

    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
    });
  }

  Future<void> speakWarning(DrowsinessSeverity severity) async {
    final now = DateTime.now();
    final timeSinceLastSpeech = _lastSpokenTime != null 
        ? now.difference(_lastSpokenTime!) 
        : Duration.zero;

    final cooldown = severity == DrowsinessSeverity.danger || severity == DrowsinessSeverity.emergency
        ? _dangerCooldown
        : _normalCooldown;

    if (_isSpeaking || timeSinceLastSpeech < cooldown) return;

    _isSpeaking = true;
    _lastSpokenTime = now;

    String message;
    switch (severity) {
      case DrowsinessSeverity.tired:
        await _flutterTts.setPitch(0.9);
        await _flutterTts.setSpeechRate(0.45);
        message = "Your eyes look tired. Please stay focused and take breaks if needed.";
        break;
      case DrowsinessSeverity.danger:
        await _flutterTts.setPitch(1.2);
        await _flutterTts.setSpeechRate(0.6);
        message = "WAKE UP IMMEDIATELY! SAFETY ALERT! Your drowsiness level is critical!";
        break;
      case DrowsinessSeverity.emergency:
        await _flutterTts.setPitch(1.3);
        await _flutterTts.setSpeechRate(0.65);
        message = "SOS TRIGGERED! Please pull over safely immediately! Emergency services are being contacted!";
        break;
      case DrowsinessSeverity.safe:
      default:
        await _flutterTts.setPitch(1.0);
        await _flutterTts.setSpeechRate(0.5);
        message = "Driving status is normal. Stay alert.";
        break;
    }

    await _flutterTts.speak(message);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
    _isSpeaking = false;
  }

  bool get isSpeaking => _isSpeaking;
}
