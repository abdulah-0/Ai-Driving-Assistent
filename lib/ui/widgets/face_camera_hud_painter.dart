import 'package:flutter/material.dart';
import '../../models/face_tracking_data.dart';
import '../../themes/app_theme.dart';

class FaceCameraHudPainter extends CustomPainter {
  final FaceTrackingData faceTracking;

  FaceCameraHudPainter({required this.faceTracking});

  @override
  void paint(Canvas canvas, Size size) {
    final cyanPaint = Paint()
      ..color = AppTheme.neonCyan
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final greenPaint = Paint()
      ..color = AppTheme.electricGreen
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final textPainter = TextPainter(
      textAlign: TextAlign.left,
      textDirection: TextDirection.ltr,
    );

    if (faceTracking.isFaceDetected && faceTracking.boundingBox != null) {
      final box = faceTracking.boundingBox!;
      final scaleX = size.width / 400;
      final scaleY = size.height / 400;

      final scaledRect = Rect.fromLTRB(
        box.left * scaleX,
        box.top * scaleY,
        box.right * scaleX,
        box.bottom * scaleY,
      );

      _drawTrackingBrackets(canvas, scaledRect, cyanPaint);

      if (faceTracking.leftEyePosition != null) {
        final leftEye = Offset(
          faceTracking.leftEyePosition!.dx * scaleX,
          faceTracking.leftEyePosition!.dy * scaleY,
        );
        _drawEyeMarker(canvas, leftEye, greenPaint);
      }

      if (faceTracking.rightEyePosition != null) {
        final rightEye = Offset(
          faceTracking.rightEyePosition!.dx * scaleX,
          faceTracking.rightEyePosition!.dy * scaleY,
        );
        _drawEyeMarker(canvas, rightEye, greenPaint);
      }

      textPainter.text = const TextSpan(
        text: 'AI LOCK: ON',
        style: TextStyle(
          color: AppTheme.neonCyan,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(scaledRect.left, scaledRect.top - 18));
    } else {
      textPainter.text = const TextSpan(
        text: 'SEARCHING...',
        style: TextStyle(
          color: AppTheme.warningAmber,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, const Offset(8, 8));
    }

    textPainter.text = TextSpan(
      text: 'FPS: ${faceTracking.fps.toStringAsFixed(1)}',
      style: const TextStyle(
        color: AppTheme.electricGreen,
        fontSize: 10,
        fontWeight: FontWeight.bold,
        fontFamily: 'monospace',
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width - textPainter.width - 8, 8));

    _drawScanningGrid(canvas, size);
  }

  void _drawTrackingBrackets(Canvas canvas, Rect rect, Paint paint) {
    final bracketSize = 20.0;

    canvas.drawLine(
      Offset(rect.left, rect.top),
      Offset(rect.left + bracketSize, rect.top),
      paint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.top),
      Offset(rect.left, rect.top + bracketSize),
      paint,
    );

    canvas.drawLine(
      Offset(rect.right - bracketSize, rect.top),
      Offset(rect.right, rect.top),
      paint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.top),
      Offset(rect.right, rect.top + bracketSize),
      paint,
    );

    canvas.drawLine(
      Offset(rect.left, rect.bottom - bracketSize),
      Offset(rect.left, rect.bottom),
      paint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.bottom),
      Offset(rect.left + bracketSize, rect.bottom),
      paint,
    );

    canvas.drawLine(
      Offset(rect.right, rect.bottom - bracketSize),
      Offset(rect.right, rect.bottom),
      paint,
    );
    canvas.drawLine(
      Offset(rect.right - bracketSize, rect.bottom),
      Offset(rect.right, rect.bottom),
      paint,
    );
  }

  void _drawEyeMarker(Canvas canvas, Offset position, Paint paint) {
    canvas.drawCircle(position, 8, paint);
    canvas.drawCircle(position, 4, paint..strokeWidth = 1);
  }

  void _drawScanningGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppTheme.neonCyan.withOpacity(0.05)
      ..strokeWidth = 0.5;

    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant FaceCameraHudPainter oldDelegate) {
    return oldDelegate.faceTracking != faceTracking;
  }
}
