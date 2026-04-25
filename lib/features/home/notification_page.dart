import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/disease_model.dart';
import '../../widgests/translated_text.dart';
import '../../services/language_provider.dart';

class NotificationPage extends StatelessWidget {
  final List<Disease> diseases;

  const NotificationPage({
    required this.diseases,
    super.key,
  });

  // =========================
  // SEVERITY COLORS
  // =========================
  Color _severityTextColor(String sev, bool isDark) {
    final s = sev.toLowerCase();

    if (s.contains('high') || s.contains('severe')) {
      return isDark ? Colors.redAccent : Colors.red;
    }

    if (s.contains('medium') || s.contains('moderate')) {
      return isDark ? Colors.deepOrangeAccent : Colors.orange;
    }

    return isDark ? const Color(0xFF66BB6A) : const Color(0xFF2E7D32);
  }

  Color _severityBadgeColor(String sev, bool isDark) {
    final s = sev.toLowerCase();

    if (s.contains('high') || s.contains('severe')) {
      return isDark
          ? Colors.redAccent.withOpacity(0.14)
          : const Color(0xFFFFEBEE);
    }

    if (s.contains('medium') || s.contains('moderate')) {
      return isDark
          ? Colors.deepOrangeAccent.withOpacity(0.12)
          : const Color(0xFFFFF3E0);
    }

    return isDark
        ? Colors.green.withOpacity(0.12)
        : const Color(0xFFF1F8F4);
  }

  Color _severityIconBg(String sev, bool isDark) {
    final s = sev.toLowerCase();

    if (s.contains('high') || s.contains('severe')) {
      return isDark
          ? Colors.redAccent.withOpacity(0.15)
          : const Color(0xFFFFEBEE);
    }

    if (s.contains('medium') || s.contains('moderate')) {
      return isDark
          ? Colors.orange.withOpacity(0.15)
          : const Color(0xFFFFF3E0);
    }

    return isDark
        ? Colors.green.withOpacity(0.15)
        : const Color(0xFFEAF8E7);
  }

  IconData _severityIcon(String sev) {
    final s = sev.toLowerCase();

    if (s.contains('high') || s.contains('severe')) {
      return Icons.warning_rounded;
    }

    if (s.contains('medium') || s.contains('moderate')) {
      return Icons.warning_amber_rounded;
    }

    return Icons.check_circle_rounded;
  }

  IconData _notificationIcon(String sev) {
    final s = sev.toLowerCase();

    if (s.contains('high') || s.contains('severe')) {
      return Icons.notifications_active_rounded;
    }

    if (s.contains('medium') || s.contains('moderate')) {
      return Icons.notifications_rounded;
    }

    return Icons.notifications_none_rounded;
  }

  String _formatSeverity(String sev) {
    final s = sev.toLowerCase();

    if (s.contains('high') || s.contains('severe')) return 'High';
    if (s.contains('medium') || s.contains('moderate')) return 'Medium';
    return 'Low';
  }

  String _formatCrop(String crop) {
    final c = crop.toLowerCase().trim();

    if (c == 'tea') return 'Tea';
    if (c == 'rice' || c == 'paddy') return 'Rice';
    if (c == 'coconut') return 'Coconut';

    if (crop.trim().isEmpty) return 'Crop';

    return crop[0].toUpperCase() + crop.substring(1);
  }

  String _riskPercentText(Disease d) {
    final double percent = d.percent;

    if (percent > 0) {
      return '${(percent * 100).toStringAsFixed(0)}%';
    }

    if (d.score > 0) {
      return '${d.score}';
    }

    return '0%';
  }

  String _riskLabel(Disease d) {
    final severity = _formatSeverity(d.severity);

    if (severity == 'High') return 'High weather risk';
    if (severity == 'Medium') return 'Medium weather risk';
    return 'Low weather risk';
  }

  int _sortRisk(Disease a, Disease b) {
    int rank(String sev) {
      final s = sev.toLowerCase();

      if (s.contains('high') || s.contains('severe')) return 3;
      if (s.contains('medium') || s.contains('moderate')) return 2;
      if (s.contains('low')) return 1;

      return 0;
    }

    final sevCompare = rank(b.severity).compareTo(rank(a.severity));
    if (sevCompare != 0) return sevCompare;

    final percentCompare = b.percent.compareTo(a.percent);
    if (percentCompare != 0) return percentCompare;

    return a.crop.toLowerCase().compareTo(b.crop.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Listen to language provider so page rebuilds after language change
    Provider.of<LanguageProvider>(context);

    final List<Disease> displayDiseases = [...diseases]..sort(_sortRisk);

    final Color bgColor =
        isDark ? const Color(0xFF0B0F14) : const Color(0xFFF6F7F9);

    final Color appBarColor =
        isDark ? const Color(0xFF0B0F14) : const Color(0xFFF6F7F9);

    final Color cardColor = isDark ? const Color(0xFF161B22) : Colors.white;

    final Color mainText = isDark ? Colors.white : Colors.black87;
    final Color subText = isDark ? Colors.white60 : Colors.black54;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(
          color: mainText,
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: mainText,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: TranslatedText(
          'Weather Risk Alerts',
          style: TextStyle(
            color: mainText,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: displayDiseases.isEmpty
            ? _EmptyRiskView(
                isDark: isDark,
                mainText: mainText,
                subText: subText,
              )
            : ListView.separated(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: displayDiseases.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, idx) {
                  final d = displayDiseases[idx];

                  final String sev = _formatSeverity(d.severity);
                  final Color sevColor = _severityTextColor(sev, isDark);
                  final String crop = _formatCrop(d.crop);
                  final String riskValue = _riskPercentText(d);

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.06)
                            : Colors.black.withOpacity(0.04),
                        width: 1,
                      ),
                      boxShadow: isDark
                          ? null
                          : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: _severityIconBg(sev, isDark),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            _severityIcon(sev),
                            color: sevColor,
                            size: 25,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                d.name.isNotEmpty ? d.name : 'Unknown Risk',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: mainText,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  Icon(
                                    Icons.eco_rounded,
                                    size: 15,
                                    color: subText,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    crop,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: subText,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 9),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _severityBadgeColor(sev, isDark),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: TranslatedText(
                                      sev,
                                      style: TextStyle(
                                        color: sevColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.blue.withOpacity(0.12)
                                          : Colors.blue.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'Risk: $riskValue',
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.blue.shade200
                                            : Colors.blue.shade700,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 9),
                              TranslatedText(
                                _riskLabel(d),
                                style: TextStyle(
                                  color: subText,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Icon(
                              _notificationIcon(sev),
                              color: sevColor,
                              size: 22,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.green.withOpacity(0.14)
                                    : const Color(0xFFEAF8E7),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.info_outline_rounded,
                                color: isDark
                                    ? Colors.green.shade300
                                    : Colors.green.shade700,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}

// =========================
// EMPTY VIEW
// =========================
class _EmptyRiskView extends StatelessWidget {
  final bool isDark;
  final Color mainText;
  final Color subText;

  const _EmptyRiskView({
    required this.isDark,
    required this.mainText,
    required this.subText,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF102A1A)
                    : const Color(0xFFEAF8E7),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                color: Colors.green.shade600,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: TranslatedText(
                'No weather risk data available',
                style: TextStyle(
                  color: mainText,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 7),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: TranslatedText(
                  'Coconut, Tea, and Rice weather risk results will appear here after weather data is loaded.',
                  style: TextStyle(
                    color: subText,
                    fontSize: 13,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}