import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/translation_service.dart';
import '../services/language_provider.dart';

class TText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  const TText(this.text, {this.style, this.maxLines, this.overflow, super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context).language;
    return FutureBuilder<String>(
      future: TranslationService().translate(text, lang),
      builder: (context, snap) {
        final display = snap.data ?? text;
        return Text(display, style: style, maxLines: maxLines, overflow: overflow);
      },
    );
  }
}
