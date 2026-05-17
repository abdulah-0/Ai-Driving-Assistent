import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class LocationResult {
  final String name;
  final LatLng point;

  LocationResult({required this.name, required this.point});
}

class LocationSearchService {
  Future<List<LocationResult>> searchLocation(String query) async {
    if (query.length < 3) return [];

    // Biasing results to Pakistan using countrycodes=pk
    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=5&addressdetails=1&countrycodes=pk');

    try {
      final response = await http.get(url, headers: {
        'User-Agent': 'AI_Driving_Assistant_App',
        'Accept-Language': 'en', // Force English results
      });

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.map((item) {
          return LocationResult(
            name: item['display_name'],
            point: LatLng(
              double.parse(item['lat']),
              double.parse(item['lon']),
            ),
          );
        }).toList();
      }
    } catch (e) {
      print('Location search error: $e');
    }
    return [];
  }
}
