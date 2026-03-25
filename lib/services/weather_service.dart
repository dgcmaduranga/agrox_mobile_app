import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {

  // Backend base URL. Use `http://localhost:8000` as required by the app.
  // Note: when running on Android emulator you may need to use 10.0.2.2:8000.
  final String baseUrl = "http://localhost:8000";

  Future<Map<String, dynamic>> getWeather(double lat, double lon) async {

    final url = Uri.parse("$baseUrl/weather?lat=$lat&lon=$lon");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        return {
          "temp": data['temperature'],
          "humidity": data['humidity'],
          "condition": data['condition'],
        };
      } else {
        throw Exception("Failed to load weather from backend");
      }

    } catch (e) {
      throw Exception("Error connecting to backend: $e");
    }
  }
}