import 'face_tracking_data.dart';

enum DrowsinessSeverity { safe, tired, danger, emergency }

class DrowsinessState {
  final bool isDrowsy;
  final DateTime? eyesClosedSince;
  final double leftEyeOpenness;
  final double rightEyeOpenness;
  final Duration closureDuration;
  final FaceTrackingData faceTracking;
  final double drowsinessScore;
  final DrowsinessSeverity severity;
  final List<double> eyeOpennessHistory;
  final bool isSOSActive;
  final String emergencyContactNumber;

  const DrowsinessState({
    this.isDrowsy = false,
    this.eyesClosedSince,
    this.leftEyeOpenness = 1.0,
    this.rightEyeOpenness = 1.0,
    this.closureDuration = Duration.zero,
    this.faceTracking = const FaceTrackingData(),
    this.drowsinessScore = 0.0,
    this.severity = DrowsinessSeverity.safe,
    this.eyeOpennessHistory = const [],
    this.isSOSActive = false,
    this.emergencyContactNumber = '911',
  });

  DrowsinessState copyWith({
    bool? isDrowsy,
    DateTime? eyesClosedSince,
    double? leftEyeOpenness,
    double? rightEyeOpenness,
    Duration? closureDuration,
    FaceTrackingData? faceTracking,
    double? drowsinessScore,
    DrowsinessSeverity? severity,
    List<double>? eyeOpennessHistory,
    bool? isSOSActive,
    String? emergencyContactNumber,
  }) {
    return DrowsinessState(
      isDrowsy: isDrowsy ?? this.isDrowsy,
      eyesClosedSince: eyesClosedSince ?? this.eyesClosedSince,
      leftEyeOpenness: leftEyeOpenness ?? this.leftEyeOpenness,
      rightEyeOpenness: rightEyeOpenness ?? this.rightEyeOpenness,
      closureDuration: closureDuration ?? this.closureDuration,
      faceTracking: faceTracking ?? this.faceTracking,
      drowsinessScore: drowsinessScore ?? this.drowsinessScore,
      severity: severity ?? this.severity,
      eyeOpennessHistory: eyeOpennessHistory ?? this.eyeOpennessHistory,
      isSOSActive: isSOSActive ?? this.isSOSActive,
      emergencyContactNumber: emergencyContactNumber ?? this.emergencyContactNumber,
    );
  }

  factory DrowsinessState.initial() {
    return const DrowsinessState();
  }
}
