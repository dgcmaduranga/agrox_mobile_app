import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/disease_model.dart';
import '../../widgests/translated_text.dart';
import '../../services/language_provider.dart';

class NotificationPage extends StatelessWidget {
  final List<Disease> diseases;

  const NotificationPage({required this.diseases, super.key});
  Color _severityTextColor(String sev, bool isDark) {
    final s = sev.toLowerCase();
    if (s == 'high') return isDark ? Colors.redAccent : Colors.red;
    if (s == 'medium') return isDark ? Colors.deepOrangeAccent : Colors.orange;
    return isDark ? const Color(0xFF66BB6A) : const Color(0xFF2E7D32);
  }

  Color _severityBadgeColor(String sev, bool isDark) {
    final s = sev.toLowerCase();
    if (s == 'high') return isDark ? Colors.redAccent.withOpacity(0.12) : const Color(0xFFFFEBEE);
    if (s == 'medium') return isDark ? Colors.deepOrangeAccent.withOpacity(0.10) : const Color(0xFFFFF3E0);
    return isDark ? Colors.green.withOpacity(0.10) : const Color(0xFFF1F8F4);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // listen to language provider so this page rebuilds on language change
    final lang = Provider.of<LanguageProvider>(context);
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color.fromARGB(255, 240, 244, 240),
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        title: TranslatedText('weather risk alerts', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : const Color.fromARGB(255, 7, 6, 6)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: diseases.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, idx) {
          final d = diseases[idx];
          final sev = (d.severity ?? 'low').toString();
          final score = d.score;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.2), width: 1.0),
              boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black)),
                      const SizedBox(height: 6),
                      Row(children: [
                        Text(d.crop, style: TextStyle(fontSize: 13, color: isDark ? Colors.white.withOpacity(0.6) : Colors.grey[700], fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: _severityBadgeColor(sev, isDark), borderRadius: BorderRadius.circular(8)), child: TranslatedText(sev.toLowerCase(), style: TextStyle(color: _severityTextColor(sev, isDark), fontWeight: FontWeight.w700, fontSize: 13))),
                      ]),
                    ],
                  ),
                ),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    TranslatedText('score', style: TextStyle(color: isDark ? Colors.white.withOpacity(0.6) : Colors.grey[700], fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text('$score', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black)),
                    const SizedBox(height: 8),
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: isDark ? Colors.green.withOpacity(0.2) : const Color(0xFF2E7D32),
                      child: Icon(Icons.info_outline, color: isDark ? Colors.white70 : Colors.white, size: 18),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}