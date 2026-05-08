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

      String titleCase(String value) {
        final text = value.trim();

        if (text.isEmpty) return '';

        return text
            .split(' ')
            .where((word) => word.trim().isNotEmpty)
            .map((word) {
          final w = word.trim();
          return w[0].toUpperCase() + w.substring(1).toLowerCase();
        }).join(' ');
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

      final backendDisplayCondition = toStr(data['display_condition']) ??
          toStr(data['displayCondition']);

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
      final displayLower = (backendDisplayCondition ?? '').toLowerCase();

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
          descriptionLower.contains('storm') ||
          displayLower.contains('rain') ||
          displayLower.contains('drizzle') ||
          displayLower.contains('shower') ||
          displayLower.contains('thunder') ||
          displayLower.contains('storm');

      final bool isCloudy = toBool(data['isCloudy']) ||
          toBool(data['is_cloudy']) ||
          conditionLower.contains('cloud') ||
          descriptionLower.contains('cloud') ||
          clouds >= 60;

      final bool isClear = toBool(data['isClear']) ||
          toBool(data['is_clear']) ||
          conditionLower.contains('clear') ||
          descriptionLower.contains('clear');

      String displayCondition;

      // Rain always gets priority over cloud text.
      if (hasRain) {
        if (conditionLower.contains('thunder') ||
            descriptionLower.contains('thunder') ||
            displayLower.contains('thunder')) {
          displayCondition = 'Thunderstorm';
        } else if (conditionLower.contains('drizzle') ||
            descriptionLower.contains('drizzle') ||
            displayLower.contains('drizzle')) {
          displayCondition = 'Drizzle';
        } else if (descriptionLower.contains('heavy rain') ||
            displayLower.contains('heavy rain')) {
          displayCondition = 'Heavy Rain';
        } else if (descriptionLower.contains('light rain') ||
            displayLower.contains('light rain')) {
          displayCondition = 'Light Rain';
        } else {
          displayCondition = 'Rain';
        }
      } else if (backendDisplayCondition != null &&
          backendDisplayCondition.trim().isNotEmpty) {
        displayCondition = titleCase(backendDisplayCondition);
      } else if (description.trim().isNotEmpty) {
        displayCondition = titleCase(description);
      } else if (condition.trim().isNotEmpty) {
        displayCondition = titleCase(condition);
      } else if (isCloudy) {
        displayCondition = 'Clouds';
      } else if (isClear) {
        displayCondition = 'Clear Sky';
      } else {
        displayCondition = 'Unknown';
      }

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
        'display_condition': displayCondition,

        'clouds': clouds,
        'isCloudy': isCloudy,
        'isClear': isClear,

        'sunrise': sunrise,
        'sunset': sunset,

        'rain': rain,
        'hasRain': hasRain,

        'icon': icon,

        // Keep raw response also. HomePage risk check can use this.
        'raw': data,
      };
    } catch (e) {
      // ignore: avoid_print
      print('WeatherService.getWeather error: $e');
      return null;
    }
  }
}