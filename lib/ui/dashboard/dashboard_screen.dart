import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;
import '../../location_service.dart';
import '../../core/rule_engine.dart';
import '../../core/ml_service.dart';
import '../face_camera.dart';
import '../alarm_overlay.dart';
import '../setup_screen.dart';
import '../../providers/drowsiness_provider.dart';
import '../../core/audio_service.dart';
import '../../themes/app_theme.dart';
import '../../models/drowsiness_state.dart';
import '../widgets/glass_card.dart';
import 'widgets/eye_metrics_card.dart';
import 'widgets/telematics_card.dart';
import 'widgets/sos_emergency_panel.dart';

class DashboardScreen extends StatefulWidget {
  final LatLng? startPoint;
  final LatLng? endPoint;

  const DashboardScreen({super.key, this.startPoint, this.endPoint});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();
  final RuleEngine _ruleEngine = RuleEngine();
  final AudioService _audioService = AudioService();
  late final MLService _mlService;

  LatLng _currentPosition = const LatLng(33.6844, 73.0479);
  double _currentHeading = 0.0;
  int _currentSpeed = 0;
  bool _isPermissionGranted = false;
  List<LatLng> _routePoints = [];
  double _totalOriginalDistance = 0;
  double _totalOriginalDurationSeconds = 0;

  String _distanceRemainingText = "-- km";
  String _timeRemainingText = "-- min";

  Color _statusColor = AppTheme.electricGreen;
  String _statusText = "SYSTEM ACTIVE: SAFE";

  bool _isDarkMode = true;
  bool _isSimulating = false;
  bool _isFollowMode = true;
  int _simulationIndex = 0;
  int _speedMultiplier = 1;
  Timer? _simulationTimer;

  @override
  void initState() {
    super.initState();
    _mlService = MLService();
    _mlService.initialize();
    
    if (widget.startPoint != null) {
      _currentPosition = widget.startPoint!;
    }

    _mlService.eyeDataStream.listen((eyeData) {
      if (eyeData.hasValidData) {
        context.read<DrowsinessProvider>().updateEyeOpenness(
          eyeData.leftEyeOpenProbability!,
          eyeData.rightEyeOpenProbability!,
        );
      }
    });
    
    _initializeTracking();
    if (widget.startPoint != null && widget.endPoint != null) {
      _fetchRoute(widget.startPoint!, widget.endPoint!);
    }
  }

  Future<void> _fetchRoute(LatLng start, LatLng end) async {
    final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=polyline');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry'];
          _totalOriginalDistance = (route['distance'] as num).toDouble();
          _totalOriginalDurationSeconds = (route['duration'] as num).toDouble();

          setState(() {
            _routePoints = _decodePolyline(geometry);
            _updateRouteLabels();
          });
          
          if (_routePoints.isNotEmpty) {
            final bounds = LatLngBounds.fromPoints(_routePoints);
            _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(70)));
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching route: $e');
    }
  }

  void _updateRouteLabels() {
    if (_routePoints.isEmpty) return;
    
    double remainingRatio = (_routePoints.length - _simulationIndex) / _routePoints.length;
    if (remainingRatio < 0) remainingRatio = 0;

    double remainingDistanceKm = (_totalOriginalDistance * remainingRatio) / 1000.0;
    double adjustedDurationSeconds = (_totalOriginalDurationSeconds * remainingRatio) / _speedMultiplier;
    double adjustedMinutes = adjustedDurationSeconds / 60.0;

    setState(() {
      _distanceRemainingText = "${remainingDistanceKm.toStringAsFixed(1)} km";
      _timeRemainingText = "${adjustedMinutes.round()} min";
    });
  }

  List<LatLng> _decodePolyline(String str) {
    List<LatLng> polyline = [];
    int index = 0, len = str.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = str.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = str.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      polyline.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return polyline;
  }

  Future<void> _initializeTracking() async {
    bool granted = await _locationService.requestLocationPermission();
    setState(() {
      _isPermissionGranted = granted;
    });

    if (granted && !_isSimulating) {
      _locationService.getLiveLocationStream().listen((Position position) {
        if (mounted && !_isSimulating) {
          setState(() {
            _currentHeading = position.heading;
            _currentPosition = LatLng(position.latitude, position.longitude);
            _currentSpeed = (position.speed * 3.6).round();
          });

          _ruleEngine.updateAreaSpeedLimit(_currentPosition.latitude, _currentPosition.longitude);
          bool shouldWarn = _ruleEngine.analyzeSpeed(_currentSpeed, (newColor, newText) {
            if (mounted) {
              setState(() {
                _statusColor = newColor;
                _statusText = newText;
              });
            }
          });

          if (shouldWarn) {
            _audioService.playWarningOnce();
          }

          if (_isFollowMode) {
            _mapController.move(_currentPosition, _mapController.camera.zoom);
          }
        }
      });
    }
  }

  void _recenterToCurrentLocation() async {
    setState(() {
      _isFollowMode = true;
    });
    try {
      Position position = await Geolocator.getCurrentPosition();
      LatLng current = LatLng(position.latitude, position.longitude);
      _mapController.move(current, 16.0);
      setState(() {
        _currentPosition = current;
        _currentHeading = position.heading;
      });
    } catch (e) {
      debugPrint("Error recentering: $e");
    }
  }

  void _startSimulation() {
    if (_routePoints.isEmpty) return;
    
    _simulationTimer?.cancel();
    setState(() {
      _isSimulating = true;
      _simulationIndex = 0;
    });

    _runSimulationLoop();
  }

  void _runSimulationLoop() {
    _simulationTimer?.cancel();
    _simulationTimer = Timer.periodic(
      Duration(milliseconds: (800 / _speedMultiplier).round()),
      (timer) {
        if (_simulationIndex < _routePoints.length) {
          LatLng nextPos = _routePoints[_simulationIndex];
          
          double heading = 0;
          if (_simulationIndex > 0) {
            heading = _calculateBearing(_routePoints[_simulationIndex - 1], nextPos);
          }

          setState(() {
            _currentHeading = heading;
            _currentPosition = nextPos;
            _currentSpeed = (40 + (10 * _speedMultiplier)).round();
            _simulationIndex++;
            _updateRouteLabels();
          });
          
          _ruleEngine.updateAreaSpeedLimit(_currentPosition.latitude, _currentPosition.longitude);
          bool shouldWarn = _ruleEngine.analyzeSpeed(_currentSpeed, (newColor, newText) {
            if (mounted) {
              setState(() {
                _statusColor = newColor;
                _statusText = newText;
              });
            }
          });

          if (shouldWarn) {
            _audioService.playWarningOnce();
          }

          if (_isFollowMode) {
            _mapController.move(_currentPosition, _mapController.camera.zoom);
          }
        } else {
          _stopSimulation();
        }
      },
    );
  }

  double _calculateBearing(LatLng start, LatLng end) {
    double lat1 = start.latitude * math.pi / 180;
    double lon1 = start.longitude * math.pi / 180;
    double lat2 = end.latitude * math.pi / 180;
    double lon2 = end.longitude * math.pi / 180;

    double dLon = lon2 - lon1;
    double y = math.sin(dLon) * math.cos(lat2);
    double x = math.cos(lat1) * math.sin(lat2) - math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    double brng = math.atan2(y, x);
    return (brng * 180 / math.pi + 360) % 360;
  }

  void _stopSimulation() {
    _simulationTimer?.cancel();
    setState(() {
      _isSimulating = false;
      _currentSpeed = 0;
    });
  }

  @override
  void dispose() {
    _mlService.dispose();
    _simulationTimer?.cancel();
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isPermissionGranted) {
      return const Scaffold(
        body: Center(child: Text("Please grant location permissions.")),
      );
    }

    return Consumer<DrowsinessProvider>(
      builder: (context, drowsinessProvider, child) {
        final severity = drowsinessProvider.severity;
        Color severityColor;
        String severityText;
        IconData severityIcon;
        
        switch (severity) {
          case DrowsinessSeverity.safe:
            severityColor = AppTheme.electricGreen;
            severityText = 'ACTIVE';
            severityIcon = Icons.verified_user_rounded;
            break;
          case DrowsinessSeverity.tired:
            severityColor = AppTheme.warningAmber;
            severityText = 'TIRED';
            severityIcon = Icons.warning_amber_rounded;
            break;
          case DrowsinessSeverity.danger:
            severityColor = AppTheme.dangerRed;
            severityText = 'DANGER';
            severityIcon = Icons.dangerous;
            break;
          case DrowsinessSeverity.emergency:
            severityColor = AppTheme.dangerRed;
            severityText = 'EMERGENCY';
            severityIcon = Icons.emergency;
            break;
        }

        return Scaffold(
          body: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _currentPosition,
                  initialZoom: 14.0,
                  onPositionChanged: (pos, hasGesture) {
                    if (hasGesture && _isFollowMode) {
                      setState(() {
                        _isFollowMode = false;
                      });
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: _isDarkMode 
                      ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                      : 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                    subdomains: const ['a', 'b', 'c', 'd'],
                    userAgentPackageName: 'com.example.ai_driving_assistant',
                  ),
                  if (_routePoints.isNotEmpty)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _routePoints.sublist(_simulationIndex),
                          color: AppTheme.neonCyan.withOpacity(0.8),
                          strokeWidth: 6,
                        ),
                      ],
                    ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _currentPosition,
                        width: 55,
                        height: 55,
                        child: Transform.rotate(
                          angle: (_currentHeading) * math.pi / 180,
                          child: Icon(
                            Icons.navigation, 
                            color: AppTheme.neonCyan, 
                            size: 45,
                            shadows: const [Shadow(color: Colors.black45, blurRadius: 10)],
                          ),
                        ),
                      ),
                      if (widget.endPoint != null)
                        Marker(
                          point: widget.endPoint!,
                          width: 45,
                          height: 45,
                          child: const Icon(Icons.location_on, color: Colors.redAccent, size: 40),
                        ),
                    ],
                  ),
                ],
              ),

              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                left: 16,
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      _stopSimulation();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const SetupScreen()),
                      );
                    },
                  ),
                ),
              ),

              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                right: 16,
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode, color: Colors.white),
                    onPressed: () => setState(() => _isDarkMode = !_isDarkMode),
                  ),
                ),
              ),

              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                left: 75,
                right: 75,
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  borderColor: severityColor,
                  glowColor: severityColor,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(severityIcon, color: severityColor, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _statusText,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: severityColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Positioned(
                top: MediaQuery.of(context).padding.top + 65,
                left: 16,
                child: GlassCard(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _timeRemainingText,
                        style: TextStyle(
                          color: AppTheme.electricGreen, 
                          fontWeight: FontWeight.w900, 
                          fontSize: 20,
                          fontFamily: 'monospace',
                        ),
                      ),
                      Text(
                        _distanceRemainingText,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: 140,
                        height: 40,
                        child: ElevatedButton.icon(
                          onPressed: _isSimulating ? _stopSimulation : _startSimulation,
                          icon: Icon(_isSimulating ? Icons.stop_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 20),
                          label: Text(
                            _isSimulating ? "STOP" : "START", 
                            style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5, fontSize: 12)
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isSimulating ? AppTheme.dangerRed : AppTheme.neonCyan,
                            elevation: 8,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
                      ),
                      if (_isSimulating)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButton<int>(
                            value: _speedMultiplier,
                            underline: const SizedBox(),
                            dropdownColor: Colors.grey[900],
                            icon: const Icon(Icons.speed, color: AppTheme.neonCyan, size: 16),
                            items: [1, 2, 5, 10].map((int val) {
                              return DropdownMenuItem<int>(
                                value: val,
                                child: Text("${val}x", style: const TextStyle(color: Colors.white, fontSize: 11)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _speedMultiplier = val!;
                              });
                              if (_isSimulating) _runSimulationLoop();
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              Positioned(
                top: MediaQuery.of(context).padding.top + 65,
                right: 16,
                width: 120,
                height: 160,
                child: GlassCard(
                  padding: EdgeInsets.zero,
                  borderColor: AppTheme.neonCyan,
                  child: FaceCamera(mlService: _mlService),
                ),
              ),

              Positioned(
                bottom: 180,
                right: 16,
                child: FloatingActionButton(
                  mini: true,
                  heroTag: 'recenter',
                  backgroundColor: AppTheme.neonCyan,
                  child: Icon(_isFollowMode ? Icons.my_location : Icons.location_searching, color: Colors.black),
                  onPressed: _recenterToCurrentLocation,
                ),
              ),

              Positioned(
                bottom: 180,
                left: 16,
                child: const SOSEmergencyPanel(),
              ),

              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
                  decoration: const BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GlassCard(
                        padding: const EdgeInsets.all(12),
                        child: TelematicsCard(
                          currentSpeed: _currentSpeed,
                          speedLimit: _ruleEngine.speedLimit,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GlassCard(
                        padding: const EdgeInsets.all(12),
                        child: const EyeMetricsCard(),
                      ),
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
