import 'dart:ui';
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../models/eye_data.dart';
import '../models/face_tracking_data.dart';

class MLService {
  FaceDetector? _faceDetector;
  bool _isProcessingFrame = false;
  DateTime? _lastFrameProcessedTime;
  final Duration _frameThrottleDuration = const Duration(milliseconds: 80);
  final StreamController<EyeData> _eyeDataController = StreamController<EyeData>.broadcast();
  final StreamController<FaceTrackingData> _faceTrackingController = StreamController<FaceTrackingData>.broadcast();
  
  final List<DateTime> _frameTimestamps = [];
  double _currentFPS = 0.0;

  Stream<EyeData> get eyeDataStream => _eyeDataController.stream;
  Stream<FaceTrackingData> get faceTrackingStream => _faceTrackingController.stream;

  void initialize() {
    final options = FaceDetectorOptions(
      enableClassification: true,
      enableTracking: true,
      performanceMode: FaceDetectorMode.fast,
    );
    _faceDetector = FaceDetector(options: options);
  }

  Future<void> processFrame(CameraImage image, CameraDescription camera) async {
    if (_isProcessingFrame) return;

    final now = DateTime.now();
    if (_lastFrameProcessedTime != null) {
      final elapsed = now.difference(_lastFrameProcessedTime!);
      if (elapsed < _frameThrottleDuration) return;
    }

    _isProcessingFrame = true;

    try {
      _frameTimestamps.add(now);
      if (_frameTimestamps.length > 30) {
        _frameTimestamps.removeAt(0);
      }
      if (_frameTimestamps.length >= 2) {
        final timeSpan = _frameTimestamps.last.difference(_frameTimestamps.first).inMilliseconds;
        if (timeSpan > 0) {
          _currentFPS = ((_frameTimestamps.length - 1) / timeSpan * 1000);
        }
      }

      final inputImage = _convertCameraImageToInputImage(image, camera);
      if (inputImage == null) {
        _isProcessingFrame = false;
        return;
      }

      final faces = await _faceDetector!.processImage(inputImage);

      _lastFrameProcessedTime = DateTime.now();

      if (faces.isNotEmpty) {
        final face = _getLargestFace(faces);
        final eyeData = EyeData(
          leftEyeOpenProbability: face.leftEyeOpenProbability,
          rightEyeOpenProbability: face.rightEyeOpenProbability,
          timestamp: DateTime.now(),
        );

        if (eyeData.hasValidData) {
          _eyeDataController.add(eyeData);
        }

        final boundingBox = face.boundingBox;
        final leftEyeLandmark = face.landmarks[FaceLandmarkType.leftEye];
        final rightEyeLandmark = face.landmarks[FaceLandmarkType.rightEye];
        final leftEye = leftEyeLandmark?.position;
        final rightEye = rightEyeLandmark?.position;

        final faceTracking = FaceTrackingData(
          boundingBox: boundingBox,
          isFaceDetected: true,
          leftEyePosition: leftEye != null ? Offset(leftEye.x.toDouble(), leftEye.y.toDouble()) : null,
          rightEyePosition: rightEye != null ? Offset(rightEye.x.toDouble(), rightEye.y.toDouble()) : null,
          fps: _currentFPS,
          isFaceLocked: true,
        );

        _faceTrackingController.add(faceTracking);
      } else {
        final faceTracking = FaceTrackingData(
          isFaceDetected: false,
          fps: _currentFPS,
          isFaceLocked: false,
        );
        _faceTrackingController.add(faceTracking);
      }
    } catch (e) {
      debugPrint('MLService processFrame error: $e');
    } finally {
      _isProcessingFrame = false;
    }
  }

  InputImage? _convertCameraImageToInputImage(CameraImage image, CameraDescription camera) {
    try {
      final sensorOrientation = camera.sensorOrientation;
      final rotation = InputImageRotationValue.fromRawValue(sensorOrientation) ?? InputImageRotation.rotation0deg;
      final format = InputImageFormatValue.fromRawValue(image.format.raw) ?? InputImageFormat.nv21;

      if (image.planes.isEmpty) {
        return null;
      }

      // Combine all planes (Y, U, V, etc.) into a single continuous byte buffer
      final WriteBuffer allBytes = WriteBuffer();
      for (final plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );
    } catch (e) {
      debugPrint('MLService frame conversion error: $e');
      return null;
    }
  }

  Face _getLargestFace(List<Face> faces) {
    Face largestFace = faces.first;
    double largestArea = 0;

    for (final face in faces) {
      final boundingBox = face.boundingBox;
      final area = boundingBox.width * boundingBox.height;
      if (area > largestArea) {
        largestArea = area;
        largestFace = face;
      }
    }

    return largestFace;
  }

  void dispose() {
    _faceDetector?.close();
    _eyeDataController.close();
    _faceTrackingController.close();
  }
}
