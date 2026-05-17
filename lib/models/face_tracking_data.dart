import 'package:flutter/material.dart';

class FaceTrackingData {
  final Rect? boundingBox;
  final bool isFaceDetected;
  final Offset? leftEyePosition;
  final Offset? rightEyePosition;
  final double fps;
  final bool isFaceLocked;

  const FaceTrackingData({
    this.boundingBox,
    this.isFaceDetected = false,
    this.leftEyePosition,
    this.rightEyePosition,
    this.fps = 0.0,
    this.isFaceLocked = false,
  });

  FaceTrackingData copyWith({
    Rect? boundingBox,
    bool? isFaceDetected,
    Offset? leftEyePosition,
    Offset? rightEyePosition,
    double? fps,
    bool? isFaceLocked,
  }) {
    return FaceTrackingData(
      boundingBox: boundingBox ?? this.boundingBox,
      isFaceDetected: isFaceDetected ?? this.isFaceDetected,
      leftEyePosition: leftEyePosition ?? this.leftEyePosition,
      rightEyePosition: rightEyePosition ?? this.rightEyePosition,
      fps: fps ?? this.fps,
      isFaceLocked: isFaceLocked ?? this.isFaceLocked,
    );
  }

  factory FaceTrackingData.initial() {
    return const FaceTrackingData();
  }

  @override
  String toString() {
    return 'FaceTrackingData(detected: $isFaceDetected, locked: $isFaceLocked, fps: $fps)';
  }
}
