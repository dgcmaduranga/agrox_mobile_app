import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/saved_treatment_service.dart';
import '../../widgests/translated_text.dart';

class SavedTreatmentsPage extends StatelessWidget {
  const SavedTreatmentsPage({super.key});

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
    if (c == 'rice' || c == 'paddy') return 'Rice Leaf';

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
          ? Colors.redAccent.withOpacity(0.14)
          : const Color(0xFFFFEBEE);
    }

    if (r.contains('medium')) {
      return isDark
          ? Colors.orangeAccent.withOpacity(0.14)
          : const Color(0xFFFFF3E0);
    }

    return isDark ? Colors.green.withOpacity(0.14) : kLightGreen;
  }

  IconData _cropIcon(String crop) {
    final c = crop.toLowerCase().trim();

    if (c == 'tea') return Icons.eco_rounded;
    if (c == 'coconut') return Icons.park_rounded;
    if (c == 'rice' || c == 'paddy') return Icons.grass_rounded;

    return Icons.spa_rounded;
  }

  int _highCount(List<Map<String, dynamic>> items) {
    return items.where((item) {
      final risk = item['riskLevel']?.toString().toLowerCase() ?? '';
      return risk.contains('high');
    }).length;
  }

  int _mediumCount(List<Map<String, dynamic>> items) {
    return items.where((item) {
      final risk = item['riskLevel']?.toString().toLowerCase() ?? '';
      return risk.contains('medium');
    }).length;
  }

  int _lowCount(List<Map<String, dynamic>> items) {
    return items.where((item) {
      final risk = item['riskLevel']?.toString().toLowerCase() ?? '';
      return !risk.contains('high') && !risk.contains('medium');
    }).length;
  }

  // =========================
  // DELETE SINGLE TREATMENT
  // =========================
  Future<void> _deleteTreatment(
    BuildContext context,
    String id,
    bool isDark,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Text(
            'Delete Treatment',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            'Are you sure you want to delete this saved treatment?',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black87,
              height: 1.4,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await SavedTreatmentService.deleteSavedTreatment(id);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Saved treatment deleted'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  // =========================
  // CLEAR ALL
  // =========================
  Future<void> _clearAll(BuildContext context, bool isDark) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Text(
            'Clear All Treatments',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            'This will delete all saved treatments from your account.',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black87,
              height: 1.4,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Clear',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await SavedTreatmentService.clearSavedTreatments();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('All saved treatments cleared'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  // =========================
  // OPEN TREATMENT DETAILS
  // =========================
  void _openTreatmentDetails(
    BuildContext context,
    Map<String, dynamic> item,
    bool isDark,
  ) {
    final diseaseName = item['diseaseName']?.toString() ?? 'Unknown Disease';
    final crop = item['crop']?.toString() ?? 'Unknown Crop';
    final riskLevel = item['riskLevel']?.toString() ?? 'Low';
    final description =
        item['description']?.toString() ?? 'No description available.';
    final accuracy = _parseAccuracy(item['accuracy']);

    final rawTreatments = item['treatments'];
    final List<dynamic> treatments =
        rawTreatments is List ? rawTreatments : [];

    final riskColor = _riskColor(riskLevel, isDark);

    final Color sheetBg = isDark ? const Color(0xFF0B0F14) : Colors.white;
    final Color cardBg =
        isDark ? const Color(0xFF161B22) : const Color(0xFFF6F8F5);
    final Color mainText = isDark ? Colors.white : const Color(0xFF102014);
    final Color subText = isDark ? Colors.white60 : Colors.black54;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.84,
          minChildSize: 0.45,
          maxChildSize: 0.94,
          expand: false,
          builder: (context, scrollController) {
            return SafeArea(
              child: SingleChildScrollView(
                controller: scrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 48,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 18),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[700] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),

                    // =========================
                    // PREMIUM DETAIL HEADER
                    // =========================
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
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
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: kDarkGreen.withOpacity(0.24),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
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
                              color: Colors.white.withOpacity(0.16),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.18),
                              ),
                            ),
                            child: const Icon(
                              Icons.medical_services_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  diseaseName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    height: 1.15,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _formatCrop(crop),
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.78),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: _DetailBadge(
                            label: riskLevel,
                            icon: Icons.warning_rounded,
                            color: riskColor,
                            bgColor: _riskBgColor(riskLevel, isDark),
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _DetailBadge(
                            label: '${accuracy.toStringAsFixed(2)}%',
                            icon: Icons.analytics_rounded,
                            color: isDark
                                ? Colors.blue.shade200
                                : Colors.blue.shade700,
                            bgColor: isDark
                                ? Colors.blue.withOpacity(0.12)
                                : Colors.blue.withOpacity(0.08),
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    _SheetSectionTitle(
                      title: 'Description',
                      icon: Icons.description_rounded,
                      mainText: mainText,
                    ),

                    const SizedBox(height: 10),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.06)
                              : kDarkGreen.withOpacity(0.06),
                        ),
                      ),
                      child: Text(
                        description,
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black87,
                          fontSize: 14,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    _SheetSectionTitle(
                      title: 'Saved Treatment Tips',
                      icon: Icons.check_circle_rounded,
                      mainText: mainText,
                    ),

                    const SizedBox(height: 12),

                    if (treatments.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          'No treatment tips available.',
                          style: TextStyle(
                            color: subText,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    else
                      ...treatments.map((t) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withOpacity(0.06)
                                  : kDarkGreen.withOpacity(0.06),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.green.withOpacity(0.14)
                                      : kLightGreen,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.check_rounded,
                                  color: isDark
                                      ? Colors.green.shade300
                                      : kDarkGreen,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 11),
                              Expanded(
                                child: Text(
                                  t.toString(),
                                  style: TextStyle(
                                    color:
                                        isDark ? Colors.white70 : Colors.black87,
                                    fontSize: 14,
                                    height: 1.4,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // =========================
  // TOP HEADER
  // =========================
  Widget _premiumTopHeader({
    required BuildContext context,
    required bool isDark,
    required bool hasItems,
  }) {
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
              Icons.bookmark_rounded,
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
                  "Saved Treatments",
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
                  "Saved crop treatment tips 🌱",
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

          hasItems
              ? GestureDetector(
                  onTap: () => _clearAll(context, isDark),
                  child: Container(
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
                      Icons.delete_sweep_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                )
              : Container(
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
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: SavedTreatmentService.getSavedTreatments(),
          builder: (context, snapshot) {
            final savedTreatments = snapshot.data ?? [];
            final bool hasItems = savedTreatments.isNotEmpty;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                  child: _premiumTopHeader(
                    context: context,
                    isDark: isDark,
                    hasItems: hasItems,
                  ),
                ),

                const SizedBox(height: 12),

                Expanded(
                  child: Builder(
                    builder: (context) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
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

                      if (savedTreatments.isEmpty) {
                        return _EmptySavedView(
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
                                    value:
                                        _highCount(savedTreatments).toString(),
                                    color: Colors.red,
                                    isDark: isDark,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _SummaryChip(
                                    label: 'Medium',
                                    value: _mediumCount(savedTreatments)
                                        .toString(),
                                    color: Colors.orange,
                                    isDark: isDark,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _SummaryChip(
                                    label: 'Low',
                                    value: _lowCount(savedTreatments).toString(),
                                    color: kMainGreen,
                                    isDark: isDark,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // =========================
                          // LIST
                          // =========================
                          Expanded(
                            child: ListView.separated(
                              physics: const BouncingScrollPhysics(),
                              padding:
                                  const EdgeInsets.fromLTRB(16, 0, 16, 24),
                              itemCount: savedTreatments.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final item = savedTreatments[index];

                                final id = item['id']?.toString() ?? '';
                                final diseaseName =
                                    item['diseaseName']?.toString() ??
                                        'Unknown Disease';
                                final crop =
                                    item['crop']?.toString() ?? 'Unknown Crop';
                                final riskLevel =
                                    item['riskLevel']?.toString() ?? 'Low';
                                final accuracy =
                                    _parseAccuracy(item['accuracy']);
                                final createdAt = item['createdAt'];

                                final riskColor =
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
                                  child: GestureDetector(
                                    onTap: () => _openTreatmentDetails(
                                      context,
                                      item,
                                      isDark,
                                    ),
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
                                            width: 52,
                                            height: 52,
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? Colors.green
                                                      .withOpacity(0.14)
                                                  : kLightGreen,
                                              borderRadius:
                                                  BorderRadius.circular(18),
                                            ),
                                            child: Icon(
                                              Icons.bookmark_rounded,
                                              color: isDark
                                                  ? Colors.green.shade300
                                                  : kDarkGreen,
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
                                                  overflow:
                                                      TextOverflow.ellipsis,
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
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: isDark
                                                            ? Colors.green
                                                                .withOpacity(
                                                                    0.12)
                                                            : kLightGreen,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(30),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                            _cropIcon(crop),
                                                            size: 13,
                                                            color: isDark
                                                                ? Colors.green
                                                                    .shade300
                                                                : kDarkGreen,
                                                          ),
                                                          const SizedBox(
                                                              width: 4),
                                                          Text(
                                                            _formatCrop(crop),
                                                            style: TextStyle(
                                                              color: isDark
                                                                  ? Colors.green
                                                                      .shade300
                                                                  : kDarkGreen,
                                                              fontSize: 11.5,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w800,
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
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 10,
                                                        vertical: 5,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: _riskBgColor(
                                                          riskLevel,
                                                          isDark,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20),
                                                      ),
                                                      child: Text(
                                                        riskLevel,
                                                        style: TextStyle(
                                                          color: riskColor,
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w800,
                                                        ),
                                                      ),
                                                    ),
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 10,
                                                        vertical: 5,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: isDark
                                                            ? Colors.blue
                                                                .withOpacity(
                                                                    0.12)
                                                            : Colors.blue
                                                                .withOpacity(
                                                                    0.08),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20),
                                                      ),
                                                      child: Text(
                                                        '${accuracy.toStringAsFixed(2)}%',
                                                        style: TextStyle(
                                                          color: isDark
                                                              ? Colors
                                                                  .blue.shade200
                                                              : Colors
                                                                  .blue.shade700,
                                                          fontSize: 12,
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
                                                      Icons.access_time_rounded,
                                                      size: 14,
                                                      color: subText,
                                                    ),
                                                    const SizedBox(width: 5),
                                                    Expanded(
                                                      child: Text(
                                                        _formatDateTime(
                                                            createdAt),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: TextStyle(
                                                          color: subText,
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),

                                          const SizedBox(width: 6),

                                          IconButton(
                                            onPressed: id.isEmpty
                                                ? null
                                                : () => _deleteTreatment(
                                                      context,
                                                      id,
                                                      isDark,
                                                    ),
                                            icon: Icon(
                                              Icons.delete_outline_rounded,
                                              color: isDark
                                                  ? Colors.white60
                                                  : Colors.black45,
                                              size: 22,
                                            ),
                                          ),
                                        ],
                                      ),
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
            );
          },
        ),
      ),
    );
  }
}

// =========================
// DETAIL BADGE
// =========================
class _DetailBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final bool isDark;

  const _DetailBadge({
    required this.label,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withOpacity(0.18),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =========================
// SHEET SECTION TITLE
// =========================
class _SheetSectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color mainText;

  const _SheetSectionTitle({
    required this.title,
    required this.icon,
    required this.mainText,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: SavedTreatmentsPage.kDarkGreen,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: mainText,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
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
            color: SavedTreatmentsPage.kDarkGreen,
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
                  : SavedTreatmentsPage.kDarkGreen.withOpacity(0.07),
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
                'Unable to load saved treatments',
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
// EMPTY VIEW
// =========================
class _EmptySavedView extends StatelessWidget {
  final bool isDark;
  final Color mainText;
  final Color subText;

  const _EmptySavedView({
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
                  : SavedTreatmentsPage.kDarkGreen.withOpacity(0.07),
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
                      : SavedTreatmentsPage.kLightGreen,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.bookmark_border_rounded,
                  color: isDark
                      ? Colors.green.shade300
                      : SavedTreatmentsPage.kDarkGreen,
                  size: 42,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No saved treatments yet',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: mainText,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                'Save treatment tips from the detection result page.',
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