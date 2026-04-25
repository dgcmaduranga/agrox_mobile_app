import 'dart:convert';
import 'package:http/http.dart' as http;

class TranslateService {
  // Update baseUrl to point to your backend translate endpoint.
  // Keep as local host for development or change to production URL.
  static const String baseUrl = "http://192.168.8.125:8000";

  // Simple in-memory cache to avoid duplicate requests.
  static final Map<String, String> _cache = {};

  /// Translate [text] into [lang]. If lang == 'en', returns original text.
  static Future<String> translate(String text, String lang) async {
    if (text.isEmpty) return text;
    if (lang == 'en') return text;

    final key = '$lang|$text';
    if (_cache.containsKey(key)) return _cache[key]!;

    try {
      final res = await http.post(
        Uri.parse("$baseUrl/translate"),
        body: {
          'text': text,
          'lang': lang,
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final translated = data['translated'] ?? text;
        _cache[key] = translated;
        return translated;
      }

      return text;
    } catch (e) {
      return text;
    }
  }
}