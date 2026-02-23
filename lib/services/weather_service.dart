import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  final String apiKey = "YOUR_API_KEY";

  Future<Map<String, dynamic>> getWeather(double lat, double lon) async {

    final url = Uri.parse(
      "https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=6abdd1bf33168b9143043b4256d589e8&units=metric"
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      return {
        "temp": data['main']['temp'],
        "humidity": data['main']['humidity'],
        "condition": data['weather'][0]['main'],
        "city": data['name'],
      };
    } else {
      throw Exception("Failed to load weather");
    }
  }
}