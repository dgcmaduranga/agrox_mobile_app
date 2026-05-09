import 'dart:convert';
import 'package:http/http.dart' as http;

import 'api_service.dart';

class TranslateService {
  // ApiService.dart eke baseUrl ekama use karanawa
  static String get baseUrl => ApiService.baseUrl;

  // duplicate translation requests avoid karanna cache ekak
  static final Map<String, String> _cache = {};

  /// Translate [text] into [lang].
  /// lang == 'en' nam original text return karanawa.
  static Future<String> translate(String text, String lang) async {
    final cleanText = text.trim();
    final cleanLang = lang.trim().toLowerCase();

    if (cleanText.isEmpty) return text;
    if (cleanLang == 'en') return text;

    final key = '$cleanLang|$cleanText';

    if (_cache.containsKey(key)) {
      return _cache[key]!;
    }

    try {
      final uri = Uri.parse('$baseUrl/translate');

      // =====================================================
      // IMPORTANT:
      // Backend eke 422 error enne JSON body eka backend ekata
      // match nathi nisa.
      //
      // E nisa form body widiyata yawanna.
      // FastAPI Form(...) / normal body params walata meka hari.
      // =====================================================
      final res = await http
          .post(
            uri,
            headers: {
              'Accept': 'application/json',
            },
            body: {
              'text': cleanText,
              'lang': cleanLang,
            },
          )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        final translated =
            data['translated'] ??
            data['translation'] ??
            data['translated_text'] ??
            data['result'] ??
            cleanText;

        final translatedText = translated.toString();

        _cache[key] = translatedText;
        return translatedText;
      }

      // Debug walata terminal eke balanna
      print('Translate failed: ${res.statusCode}');
      print('Translate response: ${res.body}');

      return text;
    } catch (e) {
      print('Translate error: $e');
      return text;
    }
  }

  static void clearCache() {
    _cache.clear();
  }
}