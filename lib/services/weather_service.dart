import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class WeatherService {
  /// Fetches weather from backend which proxies external weather APIs.
  /// Expected backend response shape (OpenWeatherMap-like):
  /// { 'main': { 'temp': ..., 'humidity': ... }, 'weather': [{ 'description': ... }], ... }
  Future<Map<String, dynamic>?> getWeather(double lat, double lon) async {
    final url = Uri.parse('${ApiService.baseUrl}/weather?lat=$lat&lon=$lon');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 8));
      // Debug: print raw response to help trace issues
      // ignore: avoid_print
      print('WeatherService: raw response (${response.statusCode}) -> ${response.body}');

      // Additional explicit debug lines to match backend logs
      try {
        final data = json.decode(response.body);
        // ignore: avoid_print
        print('API RESPONSE: $data');
        // ignore: avoid_print
        print('HUMIDITY FROM API: ${data['main']?['humidity']}');
        // ignore: avoid_print
        print('LOCATION: ${data['name']}');
      } catch (_) {}

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;

        // If backend returned an error payload, bubble up as null so UI can handle it.
        if (data.containsKey('error')) {
          // ignore: avoid_print
          print('WeatherService: backend error -> ${data}');
          return null;
        }

        // Try to parse nested `main` structure first
        final main = data['main'] as Map<String, dynamic>?;
        final weatherList = data['weather'] as List<dynamic>?;
        final description = (weatherList != null && weatherList.isNotEmpty)
            ? (weatherList.first['description']?.toString() ?? '')
            : (data['condition']?.toString() ?? '');

        final temp = (main != null && main['temp'] != null)
          ? (main['temp'] is num ? (main['temp'] as num).toDouble() : double.tryParse(main['temp'].toString()))
          : (data['temp'] is num ? (data['temp'] as num).toDouble() : double.tryParse(data['temp']?.toString() ?? ''));

        final humidity = (main != null && main['humidity'] != null)
          ? (main['humidity'] is num ? (main['humidity'] as num).toInt() : int.tryParse(main['humidity'].toString()) ?? 0)
          : (data['humidity'] is num ? (data['humidity'] as num).toInt() : int.tryParse(data['humidity']?.toString() ?? '') ?? 0);

        final city = data['city'] ?? data['name'];

        // Debug: print parsed values to help UI troubleshooting
        // ignore: avoid_print
        print('WeatherService: parsed temp=$temp, humidity=$humidity, condition=$description, city=$city');

        return {
          'temp': temp,
          'humidity': humidity,
          'condition': description,
          'city': city,
          'raw': data,
        };
      }

      return null;
    } catch (e) {
      // ignore: avoid_print
      print('WeatherService.getWeather error: $e');
      return null;
    }
  }
}