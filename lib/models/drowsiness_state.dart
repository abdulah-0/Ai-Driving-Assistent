class DrowsinessState {
  final bool isDrowsy;
  final DateTime? eyesClosedSince;
  final double leftEyeOpenness;
  final double rightEyeOpenness;
  final Duration closureDuration;

  const DrowsinessState({
    this.isDrowsy = false,
    this.eyesClosedSince,
    this.leftEyeOpenness = 1.0,
    this.rightEyeOpenness = 1.0,
    this.closureDuration = Duration.zero,
  });

  DrowsinessState copyWith({
    bool? isDrowsy,
    DateTime? eyesClosedSince,
    double? leftEyeOpenness,
    double? rightEyeOpenness,
    Duration? closureDuration,
  }) {
    return DrowsinessState(
      isDrowsy: isDrowsy ?? this.isDrowsy,
      eyesClosedSince: eyesClosedSince ?? this.eyesClosedSince,
      leftEyeOpenness: leftEyeOpenness ?? this.leftEyeOpenness,
      rightEyeOpenness: rightEyeOpenness ?? this.rightEyeOpenness,
      closureDuration: closureDuration ?? this.closureDuration,
    );
  }

  factory DrowsinessState.initial() {
    return const DrowsinessState();
  }
}
