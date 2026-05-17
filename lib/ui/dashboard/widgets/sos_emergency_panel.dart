import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../providers/drowsiness_provider.dart';
import '../../../themes/app_theme.dart';

class SOSEmergencyPanel extends StatefulWidget {
  const SOSEmergencyPanel({super.key});

  @override
  State<SOSEmergencyPanel> createState() => _SOSEmergencyPanelState();
}

class _SOSEmergencyPanelState extends State<SOSEmergencyPanel> with SingleTickerProviderStateMixin {
  bool _isPressing = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _triggerSOS() async {
    final provider = context.read<DrowsinessProvider>();
    final contactNumber = provider.emergencyContactNumber;

    final Uri phoneUri = Uri(scheme: 'tel', path: contactNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }

    provider.resetSOS();
    setState(() {
      _isPressing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DrowsinessProvider>(
      builder: (context, provider, child) {
        return GestureDetector(
          onLongPressStart: (_) {
            setState(() {
              _isPressing = true;
            });
            Future.delayed(const Duration(milliseconds: 1500), () {
              if (_isPressing && mounted) {
                provider.triggerSOS();
                _triggerSOS();
              }
            });
          },
          onLongPressEnd: (_) {
            setState(() {
              _isPressing = false;
            });
          },
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Container(
                width: 60 * _pulseAnimation.value,
                height: 60 * _pulseAnimation.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.dangerRed.withOpacity(0.2 * _pulseAnimation.value),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.dangerRed.withOpacity(0.5 * _pulseAnimation.value),
                      blurRadius: 20 * _pulseAnimation.value,
                      spreadRadius: 5 * _pulseAnimation.value,
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [AppTheme.dangerRed, Color(0xFFD50000)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.dangerRed.withOpacity(0.6),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.emergency,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
