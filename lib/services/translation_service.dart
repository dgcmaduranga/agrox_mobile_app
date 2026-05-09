import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_service.dart';

/// TranslationService
/// ApiService.baseUrl eka use karala backend /translate endpoint ekata call karanawa.
class TranslationService {
  TranslationService._privateConstructor();

  static final TranslationService _instance =
      TranslationService._privateConstructor();

  factory TranslationService() => _instance;

  // ApiService.dart eke baseUrl ekama use karanawa
  String get baseUrl => ApiService.baseUrl;

  // cache[text] = { lang: translated }
  final Map<String, Map<String, String>> _cache = {};

  /// Translate [text] to [targetLang].
  /// targetLang == 'en' nam original text return karanawa.
  Future<String> translate(String text, String targetLang) async {
    final cleanText = text.trim();
    final lang = targetLang.trim().toLowerCase();

    if (cleanText.isEmpty) return text;
    if (lang.isEmpty || lang == 'en') return text;

    final cached = _cache[cleanText]?[lang];
    if (cached != null) return cached;

    final translated = await _callBackendTranslator(cleanText, lang);

    _cache.putIfAbsent(cleanText, () => {})[lang] = translated;

    return translated;
  }

  /// Text list ekak preload karanna.
  Future<void> preload(List<String> texts, String targetLang) async {
    final cleanLang = targetLang.trim().toLowerCase();

    if (cleanLang.isEmpty || cleanLang == 'en') return;

    final futures = texts
        .where((t) => t.trim().isNotEmpty)
        .map((t) => translate(t, cleanLang));

    await Future.wait(futures);
  }

  /// Cache clear karanna.
  void clearCache() {
    _cache.clear();
  }

  /// Backend translator call
  ///
  /// IMPORTANT:
  /// Backend eke 422 error avoid karanna JSON body yawanne na.
  /// Form body widiyata yawanne:
  /// text: cleanText
  /// lang: lang
  Future<String> _callBackendTranslator(String text, String lang) async {
    try {
      final uri = Uri.parse('$baseUrl/translate');

      final res = await http
          .post(
            uri,
            headers: {
              'Accept': 'application/json',
            },
            body: {
              'text': text,
              'lang': lang,
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
            text;

        return translated.toString();
      }

      print('Translation failed: ${res.statusCode}');
      print('Translation response: ${res.body}');

      return text;
    } catch (e) {
      print('Translation error: $e');
      return text;
    }
  }
}