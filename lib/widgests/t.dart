import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/translate_service.dart';
import '../services/language_provider.dart';

class T extends StatefulWidget {
  final String text;
  final TextStyle? style;

  const T(this.text, {this.style, super.key});

  @override
  State<T> createState() => _TState();
}

class _TState extends State<T> {
  String translated = "";
  String? _lastLang;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadIfNeeded());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadIfNeeded();
  }

  void _loadIfNeeded() {
    final lang = Provider.of<LanguageProvider>(context, listen: false).language;
    if (_lastLang == lang && translated.isNotEmpty) return;
    _lastLang = lang;
    _load(lang);
  }

  void _load(String lang) async {
    final t = await TranslateService.translate(widget.text, lang);
    if (!mounted) return;
    setState(() {
      translated = t;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Also listen to language changes to trigger rebuilds where needed
    final _ = Provider.of<LanguageProvider>(context).language;

    return Text(
      translated.isEmpty ? widget.text : translated,
      style: widget.style,
    );
  }
}