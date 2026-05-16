import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import 'location_service.dart';
import 'core/rule_engine.dart';
import 'core/ml_service.dart';
import 'ui/face_camera.dart';
import 'ui/alarm_overlay.dart';
import 'providers/drowsiness_provider.dart';

List<CameraDescription> globalCameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    globalCameras = await availableCameras();
  } catch (e) {
    print('Camera error: $e');
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
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();
  final RuleEngine _ruleEngine = RuleEngine();
  late final MLService _mlService;

  LatLng _currentPosition = const LatLng(33.5651, 73.0169);
  int _currentSpeed = 0;
  bool _isPermissionGranted = false;

  Color _statusColor = Colors.greenAccent;
  String _statusText = "SYSTEM ACTIVE: SAFE";

  @override
  void initState() {
    super.initState();
    _mlService = MLService();
    _mlService.initialize();
    _mlService.eyeDataStream.listen((eyeData) {
      if (eyeData.hasValidData) {
        context.read<DrowsinessProvider>().updateEyeOpenness(
          eyeData.leftEyeOpenProbability!,
          eyeData.rightEyeOpenProbability!,
        );
      }
    });
    _initializeTracking();
  }

  Future<void> _initializeTracking() async {
    bool granted = await _locationService.requestLocationPermission();
    setState(() {
      _isPermissionGranted = granted;
    });

    if (granted) {
      _locationService.getLiveLocationStream().listen((Position position) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _currentSpeed = (position.speed * 3.6).round();
        });

        _ruleEngine.analyzeSpeed(_currentSpeed, (newColor, newText) {
          setState(() {
            _statusColor = newColor;
            _statusText = newText;
          });
        });

        _mapController.move(_currentPosition, 16.0);
      });
    }
  }

  @override
  void dispose() {
    _mlService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isPermissionGranted) {
      return const Scaffold(
        body: Center(child: Text("Please grant location permissions to use the driving assistant.")),
      );
    }

    return Consumer<DrowsinessProvider>(
      builder: (context, drowsinessProvider, child) {
        return Scaffold(
          body: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _currentPosition,
                  initialZoom: 16.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.ai_driving_assistant',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _currentPosition,
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.navigation, color: Colors.blueAccent, size: 36),
                      ),
                    ],
                  ),
                ],
              ),

              Positioned(
                top: 50,
                left: 16,
                right: 16,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.security, color: Colors.black),
                      const SizedBox(width: 12),
                      Text(
                        _statusText,
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),

              Positioned(
                top: 120,
                right: 16,
                width: 100,
                height: 130,
                child: FaceCamera(
                  mlService: _mlService,
                ),
              ),

              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.9),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text("SPEED", style: TextStyle(color: Colors.grey, fontSize: 12)),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                "$_currentSpeed",
                                style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 4),
                              const Text("km/h", style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            drowsinessProvider.isDrowsy ? "DROWSY" : "ROUTING",
                            style: TextStyle(
                              color: drowsinessProvider.isDrowsy ? Colors.red : Colors.blueAccent,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            drowsinessProvider.isDrowsy
                                ? "EYES CLOSED!"
                                : "Monitoring...",
                            style: TextStyle(
                              fontSize: 16,
                              color: drowsinessProvider.isDrowsy ? Colors.red : Colors.white,
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),

              AlarmOverlay(isActive: drowsinessProvider.isDrowsy),
            ],
          ),
        );
      },
    );
  }
}
