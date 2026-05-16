import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../models/eye_data.dart';

class MLService {
  FaceDetector? _faceDetector;
  bool _isProcessingFrame = false;
  DateTime? _lastFrameProcessedTime;
  final Duration _frameThrottleDuration = const Duration(milliseconds: 80); // ~12.5 FPS
  final StreamController<EyeData> _eyeDataController = StreamController<EyeData>.broadcast();

  Stream<EyeData> get eyeDataStream => _eyeDataController.stream;

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

      if (image.planes.isEmpty || image.planes.first.bytes == null) {
        return null;
      }

      final plane = image.planes.first;

      return InputImage.fromBytes(
        bytes: plane.bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: plane.bytesPerRow,
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
      if (boundingBox != null) {
        final area = boundingBox.width * boundingBox.height;
        if (area > largestArea) {
          largestArea = area;
          largestFace = face;
        }
      }
    }

    return largestFace;
  }

  void dispose() {
    _faceDetector?.close();
    _eyeDataController.close();
  }
}
