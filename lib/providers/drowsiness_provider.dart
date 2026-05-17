import 'package:flutter/foundation.dart';
import '../core/rule_engine.dart';
import '../core/tts_service.dart';
import '../core/audio_service.dart';
import '../models/drowsiness_state.dart';
import '../models/face_tracking_data.dart';

class DrowsinessProvider extends ChangeNotifier {
  final RuleEngine _ruleEngine = RuleEngine();
  final TtsService _ttsService = TtsService();
  final AudioService _audioService = AudioService();

  DrowsinessState _state = DrowsinessState.initial();
  DrowsinessState get state => _state;

  bool get isDrowsy => _state.isDrowsy;
  bool get isAlarmPlaying => _audioService.isPlaying;
  DrowsinessSeverity get severity => _state.severity;
  FaceTrackingData get faceTracking => _state.faceTracking;
  double get drowsinessScore => _state.drowsinessScore;
  List<double> get eyeOpennessHistory => _state.eyeOpennessHistory;
  bool get isSOSActive => _state.isSOSActive;
  String get emergencyContactNumber => _state.emergencyContactNumber;

  int _consecutiveDrowsyFrames = 0;
  static const int _tiredThreshold = 3;
  static const int _dangerThreshold = 6;
  static const int _emergencyThreshold = 10;

  void updateEyeOpenness(double leftEye, double rightEye) {
    final avgOpenness = (leftEye + rightEye) / 2;
    final drowsyTriggered = _ruleEngine.analyzeDrowsiness(leftEye, rightEye);

    List<double> updatedHistory = List.from(_state.eyeOpennessHistory);
    updatedHistory.add(avgOpenness);
    if (updatedHistory.length > 50) {
      updatedHistory.removeAt(0);
    }

    double score = _calculateDrowsinessScore(avgOpenness, _ruleEngine.getClosureDuration() ?? Duration.zero);

    DrowsinessSeverity newSeverity = _state.severity;
    if (drowsyTriggered) {
      _consecutiveDrowsyFrames++;
      if (_consecutiveDrowsyFrames >= _emergencyThreshold) {
        newSeverity = DrowsinessSeverity.emergency;
      } else if (_consecutiveDrowsyFrames >= _dangerThreshold) {
        newSeverity = DrowsinessSeverity.danger;
      } else if (_consecutiveDrowsyFrames >= _tiredThreshold) {
        newSeverity = DrowsinessSeverity.tired;
      }
    } else {
      _consecutiveDrowsyFrames = 0;
      if (_state.severity != DrowsinessSeverity.safe) {
        newSeverity = DrowsinessSeverity.safe;
      }
    }

    final oldSeverity = _state.severity;
    final wasDrowsy = _state.isDrowsy;
    final isDrowsy = newSeverity == DrowsinessSeverity.danger || newSeverity == DrowsinessSeverity.emergency;

    _state = _state.copyWith(
      leftEyeOpenness: leftEye,
      rightEyeOpenness: rightEye,
      eyesClosedSince: _ruleEngine.getClosureDuration() != Duration.zero
          ? DateTime.now().subtract(_ruleEngine.getClosureDuration()!)
          : null,
      closureDuration: _ruleEngine.getClosureDuration() ?? Duration.zero,
      drowsinessScore: score,
      severity: newSeverity,
      eyeOpennessHistory: updatedHistory,
      isDrowsy: isDrowsy,
    );

    if (isDrowsy && !wasDrowsy) {
      _triggerAlarms();
    } else if (!isDrowsy && wasDrowsy) {
      _stopAlarms();
    }

    if (newSeverity != oldSeverity) {
      _ttsService.speakWarning(newSeverity);
    }

    notifyListeners();
  }

  void updateFaceTracking(FaceTrackingData faceTracking) {
    _state = _state.copyWith(faceTracking: faceTracking);
    notifyListeners();
  }

  void triggerSOS() {
    _state = _state.copyWith(isSOSActive: true);
    _ttsService.speakWarning(DrowsinessSeverity.emergency);
    notifyListeners();
  }

  void resetSOS() {
    _state = _state.copyWith(isSOSActive: false);
    notifyListeners();
  }

  void setEmergencyContact(String number) {
    _state = _state.copyWith(emergencyContactNumber: number);
    notifyListeners();
  }

  double _calculateDrowsinessScore(double avgOpenness, Duration closureDuration) {
    double opennessScore = (1.0 - avgOpenness).clamp(0.0, 1.0);
    double durationScore = 0.0;
    if (closureDuration != Duration.zero) {
      durationScore = (closureDuration.inMilliseconds / 2000.0).clamp(0.0, 1.0);
    }
    return (opennessScore * 0.6 + durationScore * 0.4).clamp(0.0, 1.0);
  }

  Future<void> _triggerAlarms() async {
    await _ttsService.speakWarning(_state.severity);
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
