import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'radix_cache.dart';

class LocationResult {
  final String name;
  final LatLng point;

  LocationResult({required this.name, required this.point});
}

class LocationSearchService {
  final RadixCacheService _cacheService = RadixCacheService();

  Future<List<LocationResult>> searchLocation(String query) async {
    if (query.length < 3) return [];

    final normalizedQuery = query.toLowerCase().trim();

    // 1. Try exact lookup in Radix Cache
    final cachedResults = _cacheService.get(normalizedQuery);
    if (cachedResults != null) {
      debugPrint('Radix Cache Hit for query: "$query"');
      return cachedResults;
    }

    // 2. Try prefix-match lookup if exact match not found (for smoother typing)
    final prefixMatches = _cacheService.getPrefixMatches(normalizedQuery);
    if (prefixMatches != null && prefixMatches.isNotEmpty) {
      debugPrint('Radix Cache Prefix Hit for query: "$query"');
      return prefixMatches;
    }

    // Biasing results to Pakistan using countrycodes=pk
    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=5&addressdetails=1&countrycodes=pk');

    try {
      final response = await http.get(url, headers: {
        'User-Agent': 'AI_Driving_Assistant_App',
        'Accept-Language': 'en', // Force English results
      });

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        final results = data.map((item) {
          return LocationResult(
            name: item['display_name'],
            point: LatLng(
              double.parse(item['lat']),
              double.parse(item['lon']),
            ),
          );
        }).toList();

        // 3. Cache the results in the Radix Tree
        if (results.isNotEmpty) {
          _cacheService.set(normalizedQuery, results);
          debugPrint('Radix Cache Store for query: "$query"');
        }

        return results;
      }
    } catch (e) {
      debugPrint('Location search error: $e');
    }
    return [];
  }
}
