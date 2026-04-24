import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class WeatherService {
  /// Fetches weather from backend which proxies external weather APIs.
  /// Expected backend response shape:
  /// Clean backend:
  /// {
  ///   location, temp, humidity, pressure, wind_speed,
  ///   condition, description, clouds, sunrise, sunset, rain, icon
  /// }
  ///
  /// OpenWeatherMap-like:
  /// {
  ///   name,
  ///   main: { temp, humidity, pressure, temp_max, temp_min },
  ///   weather: [{ main, description, icon }],
  ///   wind: { speed },
  ///   clouds: { all },
  ///   sys: { sunrise, sunset },
  ///   rain: { 1h / 3h }
  /// }
  Future<Map<String, dynamic>?> getWeather(double lat, double lon) async {
    final url = Uri.parse('${ApiService.baseUrl}/weather?lat=$lat&lon=$lon');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 8));

      // Debug: print raw response to help trace issues
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

        // Additional explicit debug lines to match backend logs
        // ignore: avoid_print
        print('API RESPONSE: $data');

        // ignore: avoid_print
        print('HUMIDITY FROM API: ${data?['main']?['humidity'] ?? data?['humidity']}');

        // ignore: avoid_print
        print('LOCATION: ${data?['name'] ?? data?['location'] ?? data?['city']}');
      } catch (e) {
        // ignore: avoid_print
        print('WeatherService: JSON decode error -> $e');
      }

      if (response.statusCode != 200 || data == null) {
        return null;
      }

      // If backend returned an error payload, bubble up as null so UI can handle it.
      if (data.containsKey('error')) {
        // ignore: avoid_print
        print('WeatherService: backend error -> $data');
        return null;
      }

      Map<String, dynamic>? asMap(dynamic v) {
        if (v == null) return null;
        if (v is Map<String, dynamic>) return v;
        if (v is Map) return Map<String, dynamic>.from(v);
        return null;
      }

      List<dynamic>? asList(dynamic v) {
        if (v == null) return null;
        if (v is List<dynamic>) return v;
        if (v is List) return List<dynamic>.from(v);
        return null;
      }

      double? toDouble(dynamic v) {
        if (v == null) return null;
        if (v is num) return v.toDouble();
        return double.tryParse(v.toString());
      }

      int? toInt(dynamic v) {
        if (v == null) return null;
        if (v is num) return v.toInt();
        return int.tryParse(v.toString());
      }

      String? toStr(dynamic v) {
        if (v == null) return null;
        final s = v.toString().trim();
        return s.isEmpty ? null : s;
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
          toDouble(main?['temp']) ??
          toDouble(data['temperature']) ??
          0.0;

      final tempMax = toDouble(data['temp_max']) ?? toDouble(main?['temp_max']);

      final tempMin = toDouble(data['temp_min']) ?? toDouble(main?['temp_min']);

      final humidity =
          toInt(data['humidity']) ?? toInt(main?['humidity']) ?? 0;

      final pressure =
          toInt(data['pressure']) ?? toInt(main?['pressure']) ?? 0;

      final windSpeed = toDouble(data['wind_speed']) ??
          toDouble(data['windSpeed']) ??
          toDouble(windMap?['speed']) ??
          0.0;

      final condition = toStr(data['condition']) ??
          toStr(firstWeather?['main']) ??
          toStr(data['weather_condition']) ??
          '';

      final description = toStr(data['description']) ??
          toStr(firstWeather?['description']) ??
          condition;

      final clouds = toInt(data['clouds']) ?? toInt(cloudsMap?['all']) ?? 0;

      final sunrise = toInt(data['sunrise']) ?? toInt(sysMap?['sunrise']);

      final sunset = toInt(data['sunset']) ?? toInt(sysMap?['sunset']);

      final rain = toDouble(data['rain']) ??
          toDouble(rainMap?['1h']) ??
          toDouble(rainMap?['3h']) ??
          0.0;

      final icon = toStr(data['icon']) ?? toStr(firstWeather?['icon']) ?? '';

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