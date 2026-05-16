import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../core/ml_service.dart';
import '../main.dart';

class FaceCamera extends StatefulWidget {
  final MLService mlService;

  const FaceCamera({super.key, required this.mlService});

  @override
  State<FaceCamera> createState() => _FaceCameraState();
}

class _FaceCameraState extends State<FaceCamera> {
  CameraController? _controller;
  bool _isCameraReady = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    if (globalCameras.isEmpty) return;

    final frontCamera = globalCameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => globalCameras.first,
    );

    _controller = CameraController(
      frontCamera,
      ResolutionPreset.low,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.nv21,
    );

    try {
      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isCameraReady = true;
        });
        _startImageStream(frontCamera);
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
    }
  }

  void _startImageStream(CameraDescription camera) {
    if (_controller == null) return;

    _controller!.startImageStream((CameraImage image) {
      widget.mlService.processFrame(image, camera);
    });
  }

  @override
  void dispose() {
    _controller?.stopImageStream();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraReady || _controller == null) {
      return Container(
        color: Colors.grey[900],
        child: const Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 1 / _controller!.value.aspectRatio,
        child: CameraPreview(_controller!),
      ),
    );
  }
}
