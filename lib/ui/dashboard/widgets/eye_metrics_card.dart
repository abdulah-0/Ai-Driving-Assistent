import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/drowsiness_provider.dart';
import '../../../themes/app_theme.dart';
import '../../../models/drowsiness_state.dart';

class EyeMetricsCard extends StatelessWidget {
  const EyeMetricsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DrowsinessProvider>(
      builder: (context, provider, child) {
        final state = provider.state;
        final severity = state.severity;

        Color metricColor;
        switch (severity) {
          case DrowsinessSeverity.safe:
            metricColor = AppTheme.electricGreen;
            break;
          case DrowsinessSeverity.tired:
            metricColor = AppTheme.warningAmber;
            break;
          case DrowsinessSeverity.danger:
          case DrowsinessSeverity.emergency:
            metricColor = AppTheme.dangerRed;
            break;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'EYE METRICS',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _EyeGauge(
                    label: 'LEFT',
                    value: state.leftEyeOpenness,
                    color: metricColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _EyeGauge(
                    label: 'RIGHT',
                    value: state.rightEyeOpenness,
                    color: metricColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'TELEMETRY WAVE',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: EyeOpennessWaveChart(
                history: state.eyeOpennessHistory,
                color: metricColor,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _EyeGauge extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _EyeGauge({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 70,
          width: 70,
          child: CustomPaint(
            painter: _CircularGaugePainter(
              progress: value,
              color: color,
            ),
            child: Center(
              child: Text(
                '${(value * 100).toInt()}%',
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _CircularGaugePainter extends CustomPainter {
  final double progress;
  final Color color;

  _CircularGaugePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    final bgPaint = Paint()
      ..color = color.withOpacity(0.15)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, bgPaint);

    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159 / 2,
      3.14159 * 2 * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularGaugePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class EyeOpennessWaveChart extends StatelessWidget {
  final List<double> history;
  final Color color;

  const EyeOpennessWaveChart({
    super.key,
    required this.history,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _WaveChartPainter(history: history, color: color),
      size: Size.infinite,
    );
  }
}

class _WaveChartPainter extends CustomPainter {
  final List<double> history;
  final Color color;

  _WaveChartPainter({required this.history, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (history.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    final stepX = size.width / (history.length - 1).toDouble().clamp(1.0, double.infinity);

    for (int i = 0; i < history.length; i++) {
      final x = i * stepX;
      final y = size.height - (history[i] * size.height);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WaveChartPainter oldDelegate) {
    return oldDelegate.history != history || oldDelegate.color != color;
  }
}
