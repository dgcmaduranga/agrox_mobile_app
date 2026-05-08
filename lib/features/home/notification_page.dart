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
  // APP COLORS
  // =========================
  static const Color kDarkGreen = Color(0xFF0B5D1E);
  static const Color kMainGreen = Color(0xFF1B7F35);
  static const Color kLightGreen = Color(0xFFEAF8E7);

  // =========================
  // SEVERITY COLORS
  // =========================
  Color _severityTextColor(String sev, bool isDark) {
    final s = sev.toLowerCase();

    if (s.contains('high') || s.contains('severe')) {
      return isDark ? Colors.redAccent : const Color(0xFFD32F2F);
    }

    if (s.contains('medium') || s.contains('moderate')) {
      return isDark ? Colors.orangeAccent : const Color(0xFFF57C00);
    }

    return isDark ? const Color(0xFF66BB6A) : kDarkGreen;
  }

  Color _severityBadgeColor(String sev, bool isDark) {
    final s = sev.toLowerCase();

    if (s.contains('high') || s.contains('severe')) {
      return isDark
          ? Colors.redAccent.withOpacity(0.15)
          : const Color(0xFFFFEBEE);
    }

    if (s.contains('medium') || s.contains('moderate')) {
      return isDark
          ? Colors.orangeAccent.withOpacity(0.14)
          : const Color(0xFFFFF3E0);
    }

    return isDark ? Colors.green.withOpacity(0.13) : kLightGreen;
  }

  Color _severityIconBg(String sev, bool isDark) {
    final s = sev.toLowerCase();

    if (s.contains('high') || s.contains('severe')) {
      return isDark
          ? Colors.redAccent.withOpacity(0.16)
          : const Color(0xFFFFEBEE);
    }

    if (s.contains('medium') || s.contains('moderate')) {
      return isDark
          ? Colors.orangeAccent.withOpacity(0.15)
          : const Color(0xFFFFF3E0);
    }

    return isDark ? Colors.green.withOpacity(0.15) : kLightGreen;
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

  int _severityRank(String sev) {
    final s = sev.toLowerCase();

    if (s.contains('high') || s.contains('severe')) return 3;
    if (s.contains('medium') || s.contains('moderate')) return 2;
    if (s.contains('low')) return 1;

    return 0;
  }

  int _cropOrder(String crop) {
    final c = crop.toLowerCase().trim();

    if (c == 'rice' || c == 'paddy') return 0;
    if (c == 'tea') return 1;
    if (c == 'coconut') return 2;

    return 99;
  }

  int _sortRisk(Disease a, Disease b) {
    final sevCompare = _severityRank(b.severity).compareTo(
      _severityRank(a.severity),
    );

    if (sevCompare != 0) return sevCompare;

    final percentCompare = b.percent.compareTo(a.percent);
    if (percentCompare != 0) return percentCompare;

    final scoreCompare = b.score.compareTo(a.score);
    if (scoreCompare != 0) return scoreCompare;

    final cropCompare = _cropOrder(a.crop).compareTo(_cropOrder(b.crop));
    if (cropCompare != 0) return cropCompare;

    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }

  int _highCount(List<Disease> list) {
    return list.where((d) {
      final s = d.severity.toLowerCase();
      return s.contains('high') || s.contains('severe');
    }).length;
  }

  int _mediumCount(List<Disease> list) {
    return list.where((d) {
      final s = d.severity.toLowerCase();
      return s.contains('medium') || s.contains('moderate');
    }).length;
  }

  int _lowCount(List<Disease> list) {
    return list.where((d) {
      final s = d.severity.toLowerCase();
      return s.contains('low') ||
          (!s.contains('high') &&
              !s.contains('severe') &&
              !s.contains('medium') &&
              !s.contains('moderate'));
    }).length;
  }

  // =========================
  // TOP GREEN HEADER
  // =========================
  Widget _premiumTopHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 12, 14, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF064E1A),
            Color(0xFF0B5D1E),
            Color(0xFF1B7F35),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: kDarkGreen.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),

          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withOpacity(0.20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.cloudy_snowing,
              color: Colors.white,
              size: 27,
            ),
          ),

          const SizedBox(width: 12),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TranslatedText(
                  "Weather Risk Alerts",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: 4),
                TranslatedText(
                  "Crop disease risk monitor 🌦️",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.20),
              ),
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    Provider.of<LanguageProvider>(context);

    final List<Disease> displayDiseases = [...diseases]..sort(_sortRisk);

    final Color bgColor =
        isDark ? const Color(0xFF0B0F14) : const Color(0xFFF6F8F5);

    final Color cardColor = isDark ? const Color(0xFF161B22) : Colors.white;

    final Color mainText = isDark ? Colors.white : const Color(0xFF102014);
    final Color subText = isDark ? Colors.white60 : Colors.black54;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              child: _premiumTopHeader(context),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: displayDiseases.isEmpty
                  ? _EmptyRiskView(
                      isDark: isDark,
                      mainText: mainText,
                      subText: subText,
                    )
                  : Column(
                      children: [
                        // =========================
                        // SUMMARY CHIPS
                        // =========================
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: _SummaryChip(
                                  label: 'High',
                                  value: _highCount(displayDiseases).toString(),
                                  color: Colors.red,
                                  isDark: isDark,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _SummaryChip(
                                  label: 'Medium',
                                  value:
                                      _mediumCount(displayDiseases).toString(),
                                  color: Colors.orange,
                                  isDark: isDark,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _SummaryChip(
                                  label: 'Low',
                                  value: _lowCount(displayDiseases).toString(),
                                  color: kMainGreen,
                                  isDark: isDark,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // =========================
                        // ALERT LIST
                        // =========================
                        Expanded(
                          child: ListView.separated(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            itemCount: displayDiseases.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, idx) {
                              final d = displayDiseases[idx];

                              final String sev = _formatSeverity(d.severity);
                              final Color sevColor =
                                  _severityTextColor(sev, isDark);
                              final String crop = _formatCrop(d.crop);
                              final String riskValue = _riskPercentText(d);

                              return TweenAnimationBuilder(
                                duration: Duration(
                                  milliseconds: 260 + (idx * 40),
                                ),
                                tween: Tween<double>(begin: 0, end: 1),
                                builder: (context, double value, child) {
                                  return Transform.translate(
                                    offset: Offset(0, 18 * (1 - value)),
                                    child: Opacity(
                                      opacity: value,
                                      child: child,
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: cardColor,
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white.withOpacity(0.06)
                                          : kDarkGreen.withOpacity(0.06),
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(
                                          isDark ? 0.18 : 0.045,
                                        ),
                                        blurRadius: 14,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: _severityIconBg(sev, isDark),
                                          borderRadius:
                                              BorderRadius.circular(18),
                                        ),
                                        child: Icon(
                                          _severityIcon(sev),
                                          color: sevColor,
                                          size: 27,
                                        ),
                                      ),
                                      const SizedBox(width: 13),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            TranslatedText(
                                              d.name.isNotEmpty
                                                  ? d.name
                                                  : 'Unknown Risk',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w800,
                                                color: mainText,
                                                height: 1.1,
                                              ),
                                            ),
                                            const SizedBox(height: 7),
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: isDark
                                                        ? Colors.green
                                                            .withOpacity(0.12)
                                                        : kLightGreen,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      30,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.eco_rounded,
                                                        size: 13,
                                                        color: isDark
                                                            ? Colors
                                                                .green.shade300
                                                            : kDarkGreen,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        crop,
                                                        style: TextStyle(
                                                          fontSize: 11.5,
                                                          color: isDark
                                                              ? Colors.green
                                                                  .shade300
                                                              : kDarkGreen,
                                                          fontWeight:
                                                              FontWeight.w800,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: _severityBadgeColor(
                                                      sev,
                                                      isDark,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      30,
                                                    ),
                                                  ),
                                                  child: TranslatedText(
                                                    sev,
                                                    style: TextStyle(
                                                      color: sevColor,
                                                      fontSize: 11.5,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 10),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.monitor_heart_rounded,
                                                  size: 15,
                                                  color: subText,
                                                ),
                                                const SizedBox(width: 5),
                                                Text(
                                                  'Risk: $riskValue',
                                                  style: TextStyle(
                                                    color: subText,
                                                    fontSize: 12.5,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 7),
                                            TranslatedText(
                                              _riskLabel(d),
                                              style: TextStyle(
                                                color: subText,
                                                fontSize: 12.2,
                                                fontWeight: FontWeight.w500,
                                                height: 1.25,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Icon(
                                            _notificationIcon(sev),
                                            color: sevColor,
                                            size: 22,
                                          ),
                                          const SizedBox(height: 12),
                                          Container(
                                            width: 34,
                                            height: 34,
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? Colors.white
                                                      .withOpacity(0.06)
                                                  : kLightGreen,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.info_outline_rounded,
                                              color: isDark
                                                  ? Colors.green.shade300
                                                  : kDarkGreen,
                                              size: 18,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================
// SUMMARY CHIP
// =========================
class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.035),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.16 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            value,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 4),
          TranslatedText(
            label,
            style: TextStyle(
              color: isDark ? Colors.white60 : Colors.black54,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 28,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161B22) : Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : const Color(0xFF0B5D1E).withOpacity(0.07),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.18 : 0.05),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF102A1A)
                      : const Color(0xFFEAF8E7),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.green.shade600,
                  size: 42,
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
      ),
    );
  }
}