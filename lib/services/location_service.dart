import 'package:geolocator/geolocator.dart';
import 'geocoding_service.dart';

class LocationService {
  /// Returns map { 'lat': double, 'lon': double, 'city': String }
  static Future<Map<String, dynamic>?> getCurrentLocation({Duration timeout = const Duration(seconds: 15)}) async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) return null;

      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.bestForNavigation, timeLimit: timeout);
      final lat = pos.latitude;
      final lon = pos.longitude;

      String city = '';
      try {
        city = await GeocodingService.getBestLocationName(lat, lon);
      } catch (_) {
        city = '';
      }

      return {'lat': lat, 'lon': lon, 'city': city};
    } catch (_) {
      return null;
    }
  }
}
