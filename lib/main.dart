import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import 'ui/setup_screen.dart';
import 'providers/drowsiness_provider.dart';
import 'themes/app_theme.dart';

List<CameraDescription> globalCameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    globalCameras = await availableCameras();
  } catch (e) {
    debugPrint('Camera error: $e');
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => DrowsinessProvider(),
      child: const DrivingAssistantApp(),
    ),
  );
}

class DrivingAssistantApp extends StatelessWidget {
  const DrivingAssistantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AI Driving Assistant',
      theme: AppTheme.cyberNeonTheme,
      home: const SetupScreen(),
    );
  }
}
