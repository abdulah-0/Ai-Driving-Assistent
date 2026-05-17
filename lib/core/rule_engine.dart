import 'package:flutter/material.dart';

class RuleEngine {
  int speedLimit = 60; // Default limit

  bool _isSpeedWarningActive = false;

  DateTime? _eyesClosedTimestamp;
  bool _isDrowsy = false;
  bool _hasTriggeredDrowsyEvent = false;

  final Duration drowsyThreshold = const Duration(milliseconds: 1500);
  final double eyeClosureThreshold = 0.20;

  bool get isDrowsy => _isDrowsy;

  // Returns true if a NEW warning should be played
  bool analyzeSpeed(int currentSpeed, Function(Color, String) updateUI) {
    if (currentSpeed > speedLimit) {
      if (!_isSpeedWarningActive) {
        _isSpeedWarningActive = true;
        updateUI(Colors.redAccent, "WARNING: SPEED LIMIT EXCEEDED");
        return true; // Trigger sound
      }
    } else {
      if (_isSpeedWarningActive) {
        _isSpeedWarningActive = false;
        updateUI(Colors.greenAccent, "SYSTEM ACTIVE: SAFE");
      }
    }
    return false;
  }

  // Simulate dynamic speed limits based on coordinate "areas"
  void updateAreaSpeedLimit(double lat, double lng) {
    // This is a simple simulation. In a real app, use an Overpass API or a Road Speed API.
    // For now: Areas near Islamabad center (approx 33.7) have lower limits.
    if (lat > 33.6 && lat < 33.8) {
      speedLimit = 50; // City area
    } else {
      speedLimit = 100; // Highway area
    }
  }

  bool analyzeDrowsiness(double leftEye, double rightEye) {
    final bothEyesClosed = leftEye < eyeClosureThreshold && rightEye < eyeClosureThreshold;

    if (bothEyesClosed) {
      if (_eyesClosedTimestamp == null) {
        _eyesClosedTimestamp = DateTime.now();
        _hasTriggeredDrowsyEvent = false;
      }

      final elapsed = DateTime.now().difference(_eyesClosedTimestamp!);

      if (elapsed >= drowsyThreshold && !_hasTriggeredDrowsyEvent) {
        _isDrowsy = true;
        _hasTriggeredDrowsyEvent = true;
        return true;
      }

      return _isDrowsy;
    } else {
      _eyesClosedTimestamp = null;
      _isDrowsy = false;
      _hasTriggeredDrowsyEvent = false;
      return false;
    }
  }

  void resetDrowsiness() {
    _eyesClosedTimestamp = null;
    _isDrowsy = false;
    _hasTriggeredDrowsyEvent = false;
  }

  Duration? getClosureDuration() {
    if (_eyesClosedTimestamp == null) return Duration.zero;
    return DateTime.now().difference(_eyesClosedTimestamp!);
  }
}
