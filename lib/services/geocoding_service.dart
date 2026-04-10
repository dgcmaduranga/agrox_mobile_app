import 'dart:convert';
import 'package:http/http.dart' as http;

class GeocodingService {
  /// Uses OpenStreetMap Nominatim reverse geocoding (no API key required).
  /// Returns the most specific human-readable place using the priority:
  /// village > town > suburb > city. Returns empty string on failure.
  static Future<String> getBestLocationName(double lat, double lon) async {
    try {
      final uri = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&addressdetails=1&zoom=18');

      final resp = await http.get(uri, headers: {
        'User-Agent': 'agrox_mobile_app/1.0',
        'Accept-Language': 'en',
      }).timeout(const Duration(seconds: 8));

      if (resp.statusCode != 200) {
        // ignore: avoid_print
        print('Nominatim status ${resp.statusCode}');
        return '';
      }

      final data = json.decode(resp.body) as Map<String, dynamic>?;
      if (data == null) return '';

      final address = (data['address'] as Map<String, dynamic>?) ?? {};

      // Debug: print address fields
      // ignore: avoid_print
      print('Nominatim address fields: $address');

      // Priority: village > town > suburb > city
      final village = (address['village'] as String?)?.trim() ?? '';
      if (village.isNotEmpty) return village;

      final town = (address['town'] as String?)?.trim() ?? '';
      if (town.isNotEmpty) return town;

      final suburb = (address['suburb'] as String?)?.trim() ?? '';
      if (suburb.isNotEmpty) return suburb;

      final city = (address['city'] as String?)?.trim() ?? '';
      if (city.isNotEmpty) return city;

      return '';
    } catch (e) {
      // ignore: avoid_print
      print('GeocodingService (Nominatim) error: $e');
      return '';
    }
  }
}

