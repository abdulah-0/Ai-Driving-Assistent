import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/drowsiness_provider.dart';
import '../../../themes/app_theme.dart';

class TelematicsCard extends StatelessWidget {
  final int currentSpeed;
  final int speedLimit;

  const TelematicsCard({
    super.key,
    required this.currentSpeed,
    required this.speedLimit,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<DrowsinessProvider>(
      builder: (context, provider, child) {
        final faceTracking = provider.faceTracking;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TELEMETRICS',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _TelemetryItem(
                  icon: Icons.speed,
                  label: 'SPEED',
                  value: '$currentSpeed',
                  unit: 'km/h',
                  color: currentSpeed > speedLimit ? AppTheme.dangerRed : AppTheme.electricGreen,
                ),
                _TelemetryItem(
                  icon: Icons.satellite_alt,
                  label: 'GPS LOCK',
                  value: 'OK',
                  unit: '',
                  color: AppTheme.neonCyan,
                ),
                _TelemetryItem(
                  icon: Icons.track_changes,
                  label: 'TRACK FPS',
                  value: faceTracking.fps.toStringAsFixed(1),
                  unit: '',
                  color: AppTheme.electricGreen,
                ),
                _TelemetryItem(
                  icon: Icons.center_focus_weak,
                  label: 'FOCUS',
                  value: '${(provider.drowsinessScore * 100).toInt()}',
                  unit: '%',
                  color: provider.drowsinessScore > 0.7 ? AppTheme.dangerRed : AppTheme.electricGreen,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _TelemetryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _TelemetryItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 2),
              Text(
                unit,
                style: TextStyle(
                  color: color.withOpacity(0.7),
                  fontSize: 10,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
