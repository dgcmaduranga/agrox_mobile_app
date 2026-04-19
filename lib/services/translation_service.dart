import 'dart:async';

/// Simple translation service with in-memory caching.
/// Replace the `_callExternalTranslator` implementation with a real API
/// when ready (Google Translate, Azure Translator, etc.).
class TranslationService {
  TranslationService._privateConstructor();
  static final TranslationService _instance = TranslationService._privateConstructor();
  factory TranslationService() => _instance;

  // cache[text] = { lang: translated }
  final Map<String, Map<String, String>> _cache = {};

  /// Translate [text] to [targetLang]. If [targetLang] is 'en', returns [text].
  Future<String> translate(String text, String targetLang) async {
    final lang = (targetLang ?? 'en').toLowerCase();
    if (lang == 'en') return text;

    final cached = _cache[text]?[lang];
    if (cached != null) return cached;

    // TODO: Replace this with a real translator API call.
    final translated = await _callExternalTranslator(text, lang);

    _cache.putIfAbsent(text, () => {})[lang] = translated;
    return translated;
  }

  /// Preload a list of texts into the cache by translating them once.
  Future<void> preload(List<String> texts, String targetLang) async {
    final futures = texts.map((t) => translate(t, targetLang));
    await Future.wait(futures);
  }

  /// Clear the in-memory cache.
  void clearCache() => _cache.clear();

  // Placeholder external translator: currently returns the original text.
  // Replace this implementation to integrate with a real translation API.
  Future<String> _callExternalTranslator(String text, String lang) async {
    await Future.delayed(const Duration(milliseconds: 80));
    // no-op fallback: return the English text so UI remains stable offline
    return text;
  }
}
