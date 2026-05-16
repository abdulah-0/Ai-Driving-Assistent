class EyeData {
  final double? leftEyeOpenProbability;
  final double? rightEyeOpenProbability;
  final DateTime timestamp;

  const EyeData({
    this.leftEyeOpenProbability,
    this.rightEyeOpenProbability,
    required this.timestamp,
  });

  bool get hasValidData =>
      leftEyeOpenProbability != null && rightEyeOpenProbability != null;

  EyeData copyWith({
    double? leftEyeOpenProbability,
    double? rightEyeOpenProbability,
    DateTime? timestamp,
  }) {
    return EyeData(
      leftEyeOpenProbability: leftEyeOpenProbability ?? this.leftEyeOpenProbability,
      rightEyeOpenProbability: rightEyeOpenProbability ?? this.rightEyeOpenProbability,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() {
    return 'EyeData(left: ${leftEyeOpenProbability?.toStringAsFixed(3)}, right: ${rightEyeOpenProbability?.toStringAsFixed(3)}, time: $timestamp)';
  }
}
