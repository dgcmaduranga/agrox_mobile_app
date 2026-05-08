import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/history_service.dart';
import '../../widgests/translated_text.dart';

class DetectionHistoryPage extends StatelessWidget {
  const DetectionHistoryPage({super.key});

  // =========================
  // APP COLORS
  // =========================
  static const Color kDarkGreen = Color(0xFF0B5D1E);
  static const Color kMainGreen = Color(0xFF1B7F35);
  static const Color kLightGreen = Color(0xFFEAF8E7);

  String _formatDateTime(dynamic value) {
    try {
      DateTime dateTime;

      if (value is Timestamp) {
        dateTime = value.toDate();
      } else if (value is DateTime) {
        dateTime = value;
      } else if (value is String) {
        dateTime = DateTime.tryParse(value) ?? DateTime.now();
      } else {
        dateTime = DateTime.now();
      }

      final day = dateTime.day.toString().padLeft(2, '0');
      final month = dateTime.month.toString().padLeft(2, '0');
      final year = dateTime.year.toString();

      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');

      return '$day/$month/$year  $hour:$minute';
    } catch (_) {
      return 'Unknown date';
    }
  }

  double _parseAccuracy(dynamic value) {
    if (value == null) return 0.0;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0.0;
  }

  String _formatCrop(String crop) {
    final c = crop.toLowerCase().trim();

    if (c == 'tea') return 'Tea Leaf';
    if (c == 'coconut') return 'Coconut Leaf';
    if (c == 'rice') return 'Rice Leaf';
    if (c == 'paddy') return 'Rice Leaf';

    if (crop.isEmpty) return 'Unknown Crop';

    return crop[0].toUpperCase() + crop.substring(1);
  }

  Color _riskColor(String risk, bool isDark) {
    final r = risk.toLowerCase();

    if (r.contains('high')) {
      return isDark ? Colors.redAccent : const Color(0xFFD32F2F);
    }

    if (r.contains('medium')) {
      return isDark ? Colors.orangeAccent : const Color(0xFFF57C00);
    }

    return isDark ? Colors.green.shade300 : kDarkGreen;
  }

  Color _riskBgColor(String risk, bool isDark) {
    final r = risk.toLowerCase();

    if (r.contains('high')) {
      return isDark
          ? Colors.redAccent.withOpacity(0.15)
          : const Color(0xFFFFEBEE);
    }

    if (r.contains('medium')) {
      return isDark
          ? Colors.orangeAccent.withOpacity(0.15)
          : const Color(0xFFFFF3E0);
    }

    return isDark ? Colors.green.withOpacity(0.14) : kLightGreen;
  }

  IconData _riskIcon(String risk) {
    final r = risk.toLowerCase();

    if (r.contains('high')) return Icons.warning_rounded;
    if (r.contains('medium')) return Icons.warning_amber_rounded;
    return Icons.check_circle_rounded;
  }

  IconData _cropIcon(String crop) {
    final c = crop.toLowerCase().trim();

    if (c == 'tea') return Icons.eco_rounded;
    if (c == 'coconut') return Icons.park_rounded;
    if (c == 'rice' || c == 'paddy') return Icons.grass_rounded;

    return Icons.spa_rounded;
  }

  int _highCount(List<Map<String, dynamic>> history) {
    return history.where((item) {
      final risk = item['riskLevel']?.toString().toLowerCase() ?? '';
      return risk.contains('high');
    }).length;
  }

  int _mediumCount(List<Map<String, dynamic>> history) {
    return history.where((item) {
      final risk = item['riskLevel']?.toString().toLowerCase() ?? '';
      return risk.contains('medium');
    }).length;
  }

  int _lowCount(List<Map<String, dynamic>> history) {
    return history.where((item) {
      final risk = item['riskLevel']?.toString().toLowerCase() ?? '';
      return !risk.contains('high') && !risk.contains('medium');
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

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
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: HistoryService.getRecentDetections(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _LoadingView(
                      isDark: isDark,
                      cardColor: cardColor,
                    );
                  }

                  if (snapshot.hasError) {
                    return _ErrorView(
                      isDark: isDark,
                      mainText: mainText,
                      subText: subText,
                    );
                  }

                  final history = snapshot.data ?? [];

                  if (history.isEmpty) {
                    return _EmptyHistoryView(
                      isDark: isDark,
                      mainText: mainText,
                      subText: subText,
                    );
                  }

                  return Column(
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
                                value: _highCount(history).toString(),
                                color: Colors.red,
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _SummaryChip(
                                label: 'Medium',
                                value: _mediumCount(history).toString(),
                                color: Colors.orange,
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _SummaryChip(
                                label: 'Low',
                                value: _lowCount(history).toString(),
                                color: kMainGreen,
                                isDark: isDark,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // =========================
                      // HISTORY LIST
                      // =========================
                      Expanded(
                        child: ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: history.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = history[index];

                            final diseaseName =
                                item['diseaseName']?.toString() ??
                                    'Unknown Disease';
                            final crop =
                                item['crop']?.toString() ?? 'Unknown Crop';
                            final riskLevel =
                                item['riskLevel']?.toString() ?? 'Low';
                            final dateTime = item['dateTime'];
                            final accuracy = _parseAccuracy(item['accuracy']);

                            final Color riskColor =
                                _riskColor(riskLevel, isDark);

                            return TweenAnimationBuilder(
                              duration: Duration(
                                milliseconds: 260 + (index * 40),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 52,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        color: _riskBgColor(riskLevel, isDark),
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: Icon(
                                        _riskIcon(riskLevel),
                                        color: riskColor,
                                        size: 28,
                                      ),
                                    ),

                                    const SizedBox(width: 13),

                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            diseaseName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: mainText,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              height: 1.1,
                                            ),
                                          ),

                                          const SizedBox(height: 7),

                                          Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: isDark
                                                      ? Colors.green
                                                          .withOpacity(0.12)
                                                      : kLightGreen,
                                                  borderRadius:
                                                      BorderRadius.circular(30),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      _cropIcon(crop),
                                                      size: 13,
                                                      color: isDark
                                                          ? Colors
                                                              .green.shade300
                                                          : kDarkGreen,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      _formatCrop(crop),
                                                      style: TextStyle(
                                                        color: isDark
                                                            ? Colors
                                                                .green.shade300
                                                            : kDarkGreen,
                                                        fontSize: 11.5,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),

                                          const SizedBox(height: 10),

                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 5,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: _riskBgColor(
                                                    riskLevel,
                                                    isDark,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  riskLevel,
                                                  style: TextStyle(
                                                    color: riskColor,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 5,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: isDark
                                                      ? Colors.blue
                                                          .withOpacity(0.12)
                                                      : Colors.blue
                                                          .withOpacity(0.08),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  '${accuracy.toStringAsFixed(2)}%',
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

                                          const SizedBox(height: 10),

                                          Row(
                                            children: [
                                              Icon(
                                                Icons.access_time_rounded,
                                                size: 14,
                                                color: subText,
                                              ),
                                              const SizedBox(width: 5),
                                              Expanded(
                                                child: Text(
                                                  _formatDateTime(dateTime),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    color: subText,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // TOP HEADER
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
              Icons.history_rounded,
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
                  "Detection History",
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
                  "Recent disease scan results 🌱",
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
              Icons.eco_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ],
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
// LOADING VIEW
// =========================
class _LoadingView extends StatelessWidget {
  final bool isDark;
  final Color cardColor;

  const _LoadingView({
    required this.isDark,
    required this.cardColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.18 : 0.05),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            color: DetectionHistoryPage.kDarkGreen,
            strokeWidth: 3,
          ),
        ),
      ),
    );
  }
}

// =========================
// ERROR VIEW
// =========================
class _ErrorView extends StatelessWidget {
  final bool isDark;
  final Color mainText;
  final Color subText;

  const _ErrorView({
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
                  : DetectionHistoryPage.kDarkGreen.withOpacity(0.07),
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
                      ? Colors.redAccent.withOpacity(0.14)
                      : const Color(0xFFFFEBEE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.red,
                  size: 42,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Unable to load detection history',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: mainText,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                'Please check your connection and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: subText,
                  fontSize: 13,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =========================
// EMPTY HISTORY VIEW
// =========================
class _EmptyHistoryView extends StatelessWidget {
  final bool isDark;
  final Color mainText;
  final Color subText;

  const _EmptyHistoryView({
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
                  : DetectionHistoryPage.kDarkGreen.withOpacity(0.07),
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
                      : DetectionHistoryPage.kLightGreen,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.history_rounded,
                  color: isDark
                      ? Colors.green.shade300
                      : DetectionHistoryPage.kDarkGreen,
                  size: 42,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No detection history yet',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: mainText,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                'Your last 5 disease detection results will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: subText,
                  fontSize: 13,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}