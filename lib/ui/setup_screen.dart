import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../core/location_search_service.dart';
import 'dashboard/dashboard_screen.dart';
import 'dart:async';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final TextEditingController _startController = TextEditingController(text: "Current Location");
  final TextEditingController _endController = TextEditingController();
  final LocationSearchService _searchService = LocationSearchService();

  List<LocationResult> _startSuggestions = [];
  List<LocationResult> _endSuggestions = [];
  bool _isSearchingStart = false;
  bool _isSearchingEnd = false;
  Timer? _debounce;

  LatLng? _startPoint;
  LatLng? _endPoint;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _startPoint = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      debugPrint("Error getting current location: $e");
    }
  }

  void _onSearchChanged(String query, bool isStart) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.length < 3) {
        setState(() {
          if (isStart) _startSuggestions = [];
          else _endSuggestions = [];
        });
        return;
      }

      setState(() {
        if (isStart) _isSearchingStart = true;
        else _isSearchingEnd = true;
      });

      final results = await _searchService.searchLocation(query);

      setState(() {
        if (isStart) {
          _startSuggestions = results;
          _isSearchingStart = false;
        } else {
          _endSuggestions = results;
          _isSearchingEnd = false;
        }
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildHeader(),
              const SizedBox(height: 40),
              _buildSearchInput(
                label: "STARTING POINT",
                controller: _startController,
                icon: Icons.my_location,
                onChanged: (val) => _onSearchChanged(val, true),
                suggestions: _startSuggestions,
                isSearching: _isSearchingStart,
                onSelected: (res) {
                  setState(() {
                    _startController.text = res.name;
                    _startPoint = res.point;
                    _startSuggestions = [];
                  });
                },
              ),
              const SizedBox(height: 24),
              _buildSearchInput(
                label: "DESTINATION",
                controller: _endController,
                icon: Icons.location_on,
                onChanged: (val) => _onSearchChanged(val, false),
                suggestions: _endSuggestions,
                isSearching: _isSearchingEnd,
                onSelected: (res) {
                  setState(() {
                    _endController.text = res.name;
                    _endPoint = res.point;
                    _endSuggestions = [];
                  });
                },
              ),
              const SizedBox(height: 40),
              _buildStartButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Where to?",
          style: TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Set your route for AI assistance",
          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildSearchInput({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required Function(String) onChanged,
    required List<LocationResult> suggestions,
    required bool isSearching,
    required Function(LocationResult) onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.blueAccent.withOpacity(0.8),
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              TextField(
                controller: controller,
                onChanged: onChanged,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  prefixIcon: Icon(icon, color: Colors.blueAccent),
                  suffixIcon: isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey, size: 20),
                        onPressed: () {
                          controller.clear();
                          onChanged("");
                        },
                      ),
                  hintText: "Search location...",
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
              if (suggestions.isNotEmpty)
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: suggestions.length,
                    separatorBuilder: (ctx, i) => Divider(color: Colors.white.withOpacity(0.1), height: 1),
                    itemBuilder: (ctx, i) {
                      final res = suggestions[i];
                      return ListTile(
                        dense: true,
                        title: Text(
                          res.name,
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => onSelected(res),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStartButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Colors.blueAccent, Color(0xFF00D2FF)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          if (_endPoint != null && _startPoint != null) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => DashboardScreen(
                  startPoint: _startPoint,
                  endPoint: _endPoint,
                ),
              ),
            );
          } else {
            String message = "Please select a destination";
            if (_startPoint == null) message = "Waiting for current location...";
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: const Text(
          "START JOURNEY",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.1,
          ),
        ),
      ),
    );
  }
}
