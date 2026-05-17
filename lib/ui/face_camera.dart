import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/ml_service.dart';
import '../main.dart';
import '../models/face_tracking_data.dart';
import '../providers/drowsiness_provider.dart';
import 'widgets/face_camera_hud_painter.dart';

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
    
    widget.mlService.faceTrackingStream.listen((faceTracking) {
      if (mounted) {
        context.read<DrowsinessProvider>().updateFaceTracking(faceTracking);
      }
    });
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

    return Consumer<DrowsinessProvider>(
      builder: (context, provider, child) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              AspectRatio(
                aspectRatio: 1 / _controller!.value.aspectRatio,
                child: CameraPreview(_controller!),
              ),
              CustomPaint(
                painter: FaceCameraHudPainter(faceTracking: provider.faceTracking),
                size: Size.infinite,
              ),
            ],
          ),
        );
      },
    );
  }
}
