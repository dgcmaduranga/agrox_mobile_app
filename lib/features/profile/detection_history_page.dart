import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/history_service.dart';

class DetectionHistoryPage extends StatelessWidget {
  const DetectionHistoryPage({super.key});

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

    if (crop.isEmpty) return 'Unknown Crop';

    return crop[0].toUpperCase() + crop.substring(1);
  }

  Color _riskColor(String risk) {
    final r = risk.toLowerCase();

    if (r.contains('high')) return Colors.red;
    if (r.contains('medium')) return Colors.orange;
    return Colors.green;
  }

  IconData _riskIcon(String risk) {
    final r = risk.toLowerCase();

    if (r.contains('high')) return Icons.warning_rounded;
    if (r.contains('medium')) return Icons.warning_amber_rounded;
    return Icons.check_circle_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color bgColor =
        isDark ? const Color(0xFF121212) : const Color(0xFFF6F7F9);

    final Color cardColor =
        isDark ? const Color(0xFF1E1E1E) : Colors.white;

    final Color mainText = isDark ? Colors.white : Colors.black87;
    final Color subText = isDark ? Colors.grey : Colors.black54;

    final Color borderColor = isDark
        ? Colors.white.withOpacity(0.04)
        : Colors.black.withOpacity(0.04);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : Colors.black,
        ),
        title: Text(
          'Detection History',
          style: TextStyle(
            color: mainText,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: HistoryService.getRecentDetections(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  color: Colors.green.shade600,
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Unable to load detection history.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: subText,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }

            final history = snapshot.data ?? [];

            if (history.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E1E1E)
                              : const Color(0xFFEAF8E7),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.history_rounded,
                          color: Colors.green.shade500,
                          size: 38,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No detection history yet',
                        style: TextStyle(
                          color: mainText,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Your last 5 disease detection results will appear here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: subText,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: history.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = history[index];

                final diseaseName =
                    item['diseaseName']?.toString() ?? 'Unknown Disease';
                final crop = item['crop']?.toString() ?? 'Unknown Crop';
                final riskLevel = item['riskLevel']?.toString() ?? 'Low';
                final dateTime = item['dateTime'];
                final accuracy = _parseAccuracy(item['accuracy']);

                final riskColor = _riskColor(riskLevel);

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                    boxShadow: isDark
                        ? null
                        : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              offset: const Offset(0, 2),
                              blurRadius: 6,
                            ),
                          ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: riskColor.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          _riskIcon(riskLevel),
                          color: riskColor,
                          size: 24,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              diseaseName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: mainText,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),

                            const SizedBox(height: 5),

                            Text(
                              _formatCrop(crop),
                              style: TextStyle(
                                color: subText,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            const SizedBox(height: 8),

                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: riskColor.withOpacity(0.14),
                                    borderRadius: BorderRadius.circular(20),
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

                                const SizedBox(width: 8),

                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(20),
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

                            const SizedBox(height: 8),

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
                                    overflow: TextOverflow.ellipsis,
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
                );
              },
            );
          },
        ),
      ),
    );
  }
}