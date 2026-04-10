import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/translate_service.dart';
import '../services/language_provider.dart';

/// A widget that displays translated text fetched from the backend.
/// It rebuilds whenever the app language (LanguageProvider) changes.
class TranslatedText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  const TranslatedText(
    this.text, {
    this.style,
    this.maxLines,
    this.overflow,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context).language;

    return FutureBuilder<String>(
      future: TranslateService.translate(text, lang),
      initialData: text,
      builder: (context, snapshot) {
        final display = snapshot.data ?? text;
        return Text(
          display,
          style: style,
          maxLines: maxLines,
          overflow: overflow,
        );
      },
    );
  }
}
