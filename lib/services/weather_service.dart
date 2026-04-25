import 'dart:convert';
import 'package:http/http.dart' as http;

import 'api_service.dart';

class WeatherService {
  /// Fetches weather from backend which proxies external weather APIs.
  /// Supports:
  /// 1. Clean backend response
  /// 2. OpenWeatherMap-like response
  Future<Map<String, dynamic>?> getWeather(double lat, double lon) async {
    final url = Uri.parse('${ApiService.baseUrl}/weather?lat=$lat&lon=$lon');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 8));

      // ignore: avoid_print
      print(
        'WeatherService: raw response (${response.statusCode}) -> ${response.body}',
      );

      Map<String, dynamic>? data;

      try {
        final decoded = json.decode(response.body);

        if (decoded is Map<String, dynamic>) {
          data = decoded;
        } else if (decoded is Map) {
          data = Map<String, dynamic>.from(decoded);
        }

        // ignore: avoid_print
        print('API RESPONSE: $data');

        // ignore: avoid_print
        print(
          'HUMIDITY FROM API: ${data?['main']?['humidity'] ?? data?['humidity']}',
        );

        // ignore: avoid_print
        print(
          'LOCATION: ${data?['name'] ?? data?['location'] ?? data?['city']}',
        );
      } catch (e) {
        // ignore: avoid_print
        print('WeatherService: JSON decode error -> $e');
      }

      if (response.statusCode != 200 || data == null) {
        return null;
      }

      if (data.containsKey('error')) {
        // ignore: avoid_print
        print('WeatherService: backend error -> $data');
        return null;
      }

      Map<String, dynamic>? asMap(dynamic value) {
        if (value == null) return null;
        if (value is Map<String, dynamic>) return value;
        if (value is Map) return Map<String, dynamic>.from(value);
        return null;
      }

      List<dynamic>? asList(dynamic value) {
        if (value == null) return null;
        if (value is List<dynamic>) return value;
        if (value is List) return List<dynamic>.from(value);
        return null;
      }

      double? toDouble(dynamic value) {
        if (value == null) return null;
        if (value is num) return value.toDouble();
        return double.tryParse(value.toString());
      }

      int? toInt(dynamic value) {
        if (value == null) return null;
        if (value is num) return value.toInt();
        return int.tryParse(value.toString());
      }

      String? toStr(dynamic value) {
        if (value == null) return null;

        final s = value.toString().trim();

        if (s.isEmpty) return null;

        return s;
      }

      bool toBool(dynamic value) {
        if (value == null) return false;

        if (value is bool) return value;

        final text = value.toString().toLowerCase().trim();

        return text == 'true' || text == '1' || text == 'yes';
      }

      final main = asMap(data['main']);
      final windMap = asMap(data['wind']);
      final cloudsMap = asMap(data['clouds']);
      final sysMap = asMap(data['sys']);
      final rainMap = asMap(data['rain']);
      final weatherList = asList(data['weather']);

      Map<String, dynamic>? firstWeather;

      if (weatherList != null && weatherList.isNotEmpty) {
        firstWeather = asMap(weatherList.first);
      }

      final location = toStr(data['location']) ??
          toStr(data['city']) ??
          toStr(data['name']) ??
          'Unknown';

      final temp = toDouble(data['temp']) ??
          toDouble(data['temperature']) ??
          toDouble(main?['temp']) ??
          0.0;

      final tempMax = toDouble(data['temp_max']) ??
          toDouble(data['tempMax']) ??
          toDouble(main?['temp_max']);

      final tempMin = toDouble(data['temp_min']) ??
          toDouble(data['tempMin']) ??
          toDouble(main?['temp_min']);

      final humidity =
          toInt(data['humidity']) ?? toInt(main?['humidity']) ?? 0;

      final pressure =
          toInt(data['pressure']) ?? toInt(main?['pressure']) ?? 0;

      final windSpeed = toDouble(data['wind_speed']) ??
          toDouble(data['windSpeed']) ??
          toDouble(windMap?['speed']) ??
          0.0;

      final condition = toStr(data['condition']) ??
          toStr(data['weather_condition']) ??
          toStr(firstWeather?['main']) ??
          '';

      final description = toStr(data['description']) ??
          toStr(firstWeather?['description']) ??
          condition;

      final clouds = toInt(data['clouds']) ?? toInt(cloudsMap?['all']) ?? 0;

      final sunrise = toInt(data['sunrise']) ?? toInt(sysMap?['sunrise']);

      final sunset = toInt(data['sunset']) ?? toInt(sysMap?['sunset']);

      final rain = toDouble(data['rain']) ??
          toDouble(data['rain_1h']) ??
          toDouble(data['rain_3h']) ??
          toDouble(rainMap?['1h']) ??
          toDouble(rainMap?['3h']) ??
          0.0;

      final icon = toStr(data['icon']) ?? toStr(firstWeather?['icon']) ?? '';

      final conditionLower = condition.toLowerCase();
      final descriptionLower = description.toLowerCase();

      final bool hasRain = toBool(data['hasRain']) ||
          toBool(data['has_rain']) ||
          rain > 0 ||
          conditionLower.contains('rain') ||
          conditionLower.contains('drizzle') ||
          conditionLower.contains('thunder') ||
          conditionLower.contains('storm') ||
          descriptionLower.contains('rain') ||
          descriptionLower.contains('drizzle') ||
          descriptionLower.contains('shower') ||
          descriptionLower.contains('thunder') ||
          descriptionLower.contains('storm');

      return {
        'location': location,
        'city': location,
        'temp': temp,
        'temp_max': tempMax,
        'temp_min': tempMin,
        'humidity': humidity,
        'pressure': pressure,
        'wind_speed': windSpeed,
        'condition': condition,
        'description': description,
        'clouds': clouds,
        'sunrise': sunrise,
        'sunset': sunset,
        'rain': rain,
        'hasRain': hasRain,
        'icon': icon,
        'raw': data,
      };
    } catch (e) {
      // ignore: avoid_print
      print('WeatherService.getWeather error: $e');
      return null;
    }
  }
}