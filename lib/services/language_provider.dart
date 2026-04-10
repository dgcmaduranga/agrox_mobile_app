import 'package:flutter/foundation.dart';
import 'app_config.dart';

class LanguageProvider extends ChangeNotifier {
  String _lang = 'en';

  String get language => _lang;

  void setLanguage(String lang) {
    if (lang == _lang) return;
    _lang = lang;
    // keep legacy AppConfig in sync for services that still use it
    try {
      AppConfig.lang = lang;
    } catch (_) {}
    notifyListeners();
  }
}