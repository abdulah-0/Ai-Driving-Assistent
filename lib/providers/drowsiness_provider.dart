import 'package:flutter/foundation.dart';
import '../core/rule_engine.dart';
import '../core/tts_service.dart';
import '../core/audio_service.dart';
import '../models/drowsiness_state.dart';

class DrowsinessProvider extends ChangeNotifier {
  final RuleEngine _ruleEngine = RuleEngine();
  final TtsService _ttsService = TtsService();
  final AudioService _audioService = AudioService();

  DrowsinessState _state = DrowsinessState.initial();
  DrowsinessState get state => _state;

  bool get isDrowsy => _state.isDrowsy;
  bool get isAlarmPlaying => _audioService.isPlaying;

  void updateEyeOpenness(double leftEye, double rightEye) {
    final drowsyTriggered = _ruleEngine.analyzeDrowsiness(leftEye, rightEye);

    _state = _state.copyWith(
      leftEyeOpenness: leftEye,
      rightEyeOpenness: rightEye,
      eyesClosedSince: _ruleEngine.getClosureDuration() != Duration.zero
          ? DateTime.now().subtract(_ruleEngine.getClosureDuration()!)
          : null,
      closureDuration: _ruleEngine.getClosureDuration() ?? Duration.zero,
    );

    if (drowsyTriggered && !_state.isDrowsy) {
      _state = _state.copyWith(isDrowsy: true);
      _triggerAlarms();
    } else if (!drowsyTriggered && _state.isDrowsy) {
      _state = _state.copyWith(isDrowsy: false);
      _stopAlarms();
    }

    notifyListeners();
  }

  Future<void> _triggerAlarms() async {
    await _ttsService.speakWarning();
    await _audioService.playAlarmLoop();
  }

  Future<void> _stopAlarms() async {
    await _ttsService.stop();
    await _audioService.stopAlarm();
  }

  @override
  void dispose() {
    _audioService.dispose();
    _ttsService.stop();
    super.dispose();
  }
}
