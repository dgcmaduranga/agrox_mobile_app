import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/saved_treatment_service.dart';

class SavedTreatmentsPage extends StatelessWidget {
  const SavedTreatmentsPage({super.key});

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

  Future<void> _deleteTreatment(
    BuildContext context,
    String id,
    bool isDark,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            'Delete Treatment',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            'Are you sure you want to delete this saved treatment?',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
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
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await SavedTreatmentService.deleteSavedTreatment(id);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saved treatment deleted'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _clearAll(BuildContext context, bool isDark) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            'Clear All Treatments',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            'This will delete all saved treatments from your account.',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
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
              ),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await SavedTreatmentService.clearSavedTreatments();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All saved treatments cleared'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openTreatmentDetails(
    BuildContext context,
    Map<String, dynamic> item,
    bool isDark,
  ) {
    final diseaseName =
        item['diseaseName']?.toString() ?? 'Unknown Disease';
    final crop = item['crop']?.toString() ?? 'Unknown Crop';
    final riskLevel = item['riskLevel']?.toString() ?? 'Low';
    final description =
        item['description']?.toString() ?? 'No description available.';
    final accuracy = _parseAccuracy(item['accuracy']);

    final rawTreatments = item['treatments'];
    final List<dynamic> treatments =
        rawTreatments is List ? rawTreatments : [];

    final riskColor = _riskColor(riskLevel);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.82,
          minChildSize: 0.45,
          maxChildSize: 0.92,
          expand: false,
          builder: (context, scrollController) {
            return SafeArea(
              child: SingleChildScrollView(
                controller: scrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
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

                    Text(
                      diseaseName,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      _formatCrop(crop),
                      style: TextStyle(
                        color: isDark ? Colors.white60 : Colors.black54,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: riskColor.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            riskLevel,
                            style: TextStyle(
                              color: riskColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
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
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    Text(
                      'Description',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF121212)
                            : const Color(0xFFF6F7F9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        description,
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black87,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    Text(
                      'Saved Treatment Tips',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 12),

                    if (treatments.isEmpty)
                      Text(
                        'No treatment tips available.',
                        style: TextStyle(
                          color: isDark ? Colors.white60 : Colors.black54,
                          fontSize: 14,
                        ),
                      )
                    else
                      ...treatments.map((t) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green.shade500,
                                size: 19,
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Text(
                                  t.toString(),
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black87,
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

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color bgColor =
        isDark ? const Color(0xFF121212) : const Color(0xFFF6F7F9);

    final Color cardColor =
        isDark ? const Color(0xFF1E1E1E) : Colors.white;

    final Color mainText = isDark ? Colors.white : Colors.black87;
    final Color subText = isDark ? Colors.grey : Colors.black54;

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
          'Saved Treatments',
          style: TextStyle(
            color: mainText,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _clearAll(context, isDark),
            icon: Icon(
              Icons.delete_sweep_rounded,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: SavedTreatmentService.getSavedTreatments(),
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
                    'Unable to load saved treatments.',
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

            final savedTreatments = snapshot.data ?? [];

            if (savedTreatments.isEmpty) {
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
                          Icons.bookmark_border_rounded,
                          color: Colors.green.shade500,
                          size: 38,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No saved treatments yet',
                        style: TextStyle(
                          color: mainText,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Save treatment tips from the detection result page.',
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
              itemCount: savedTreatments.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = savedTreatments[index];

                final id = item['id']?.toString() ?? '';
                final diseaseName =
                    item['diseaseName']?.toString() ?? 'Unknown Disease';
                final crop = item['crop']?.toString() ?? 'Unknown Crop';
                final riskLevel = item['riskLevel']?.toString() ?? 'Low';
                final accuracy = _parseAccuracy(item['accuracy']);
                final createdAt = item['createdAt'];

                final riskColor = _riskColor(riskLevel);

                return GestureDetector(
                  onTap: () => _openTreatmentDetails(context, item, isDark),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.04)
                            : Colors.black.withOpacity(0.04),
                      ),
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
                            color: Colors.green.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.bookmark_rounded,
                            color: Colors.green.shade500,
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
                                      _formatDateTime(createdAt),
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

                        IconButton(
                          onPressed: id.isEmpty
                              ? null
                              : () => _deleteTreatment(context, id, isDark),
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            color: isDark ? Colors.white60 : Colors.black45,
                            size: 21,
                          ),
                        ),
                      ],
                    ),
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