import 'package:flutter/material.dart';

import '../../services/saved_treatment_service.dart';
import '../../widgests/translated_text.dart';

class ResultPage extends StatelessWidget {
  final Map<String, dynamic> data;

  const ResultPage({super.key, required this.data});

  Future<void> _saveTreatment({
    required BuildContext context,
    required String disease,
    required String crop,
    required String risk,
    required String description,
    required List<dynamic> treatment,
    required double accuracy,
  }) async {
    try {
      final List<String> treatmentList =
          treatment.map((e) => e.toString()).toList();

      await SavedTreatmentService.saveTreatment(
        diseaseName: disease,
        crop: crop,
        riskLevel: risk,
        description: description,
        treatments: treatmentList,
        accuracy: accuracy,
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TranslatedText("✅ Treatment saved successfully"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TranslatedText("❌ Failed to save treatment"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Color _riskColor(String risk) {
    final r = risk.toLowerCase();

    if (r.contains('high')) return Colors.red;
    if (r.contains('medium') || r.contains('moderate')) return Colors.orange;

    return Colors.green;
  }

  String _formatCrop(String crop) {
    final c = crop.toLowerCase().trim();

    if (c == "tea") return "Tea Leaf";
    if (c == "coconut") return "Coconut Leaf";
    if (c == "rice") return "Rice Leaf";

    return crop.isNotEmpty ? crop : "Unknown Crop";
  }

  double _safeAccuracy(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? "0") ?? 0.0;
  }

  List<dynamic> _safeTreatment(dynamic value) {
    if (value is List && value.isNotEmpty) {
      return value;
    }

    return ["No recommendations available"];
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color scaffoldBg =
        isDark ? const Color(0xFF0B0F14) : const Color(0xFFF8F9FA);

    final Color cardBg =
        isDark ? const Color(0xFF161B22) : Colors.grey.shade100;

    final Color sectionBg =
        isDark ? const Color(0xFF161B22) : Colors.grey.shade50;

    final Color bottomBg = isDark ? const Color(0xFF0B0F14) : Colors.white;

    final Color mainText = isDark ? Colors.white : Colors.black87;

    final Color subText = isDark ? Colors.white70 : Colors.black87;

    final Color borderColor =
        isDark ? Colors.white.withOpacity(0.08) : Colors.transparent;

    final Color shadowColor =
        isDark ? Colors.black.withOpacity(0.28) : Colors.black12;

    // =========================
    // SAFE DATA
    // =========================
    final String disease =
        data["disease"]?.toString().trim().isNotEmpty == true
            ? data["disease"].toString()
            : "Unknown Disease";

    final String cropRaw =
        data["crop"]?.toString() ??
        data["selectedCrop"]?.toString() ??
        "Unknown Crop";

    final String crop = _formatCrop(cropRaw);

    final double accuracy = _safeAccuracy(data["accuracy"]);

    final String risk = data["risk"]?.toString().trim().isNotEmpty == true
        ? data["risk"].toString()
        : "Low";

    final String description =
        data["description"]?.toString().trim().isNotEmpty == true
            ? data["description"].toString()
            : "No detailed data found.";

    final List<dynamic> treatment = _safeTreatment(data["treatment"]);

    final Color riskColor = _riskColor(risk);

    return Scaffold(
      backgroundColor: scaffoldBg,

      // =========================
      // MAIN BODY
      // =========================
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // =========================
            // FIXED SMALL GREEN HEADER
            // =========================
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF006B2D),
                      Color(0xFF0A8F3C),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.25),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/home',
                          (route) => false,
                        );
                      },
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 23,
                      ),
                    ),

                    const SizedBox(width: 14),

                    Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.20),
                        ),
                      ),
                      child: const Icon(
                        Icons.verified_rounded,
                        color: Colors.white,
                        size: 27,
                      ),
                    ),

                    const SizedBox(width: 13),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TranslatedText(
                            "Detection Result",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          TranslatedText(
                            "AI crop disease report 🌱",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.88),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Container(
                      height: 44,
                      width: 44,
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
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // =========================
            // SCROLL CONTENT ONLY
            // =========================
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // =========================
                    // RESULT CARD
                    // =========================
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: shadowColor,
                            blurRadius: 10,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Disease name
                          Row(
                            children: [
                              const Icon(
                                Icons.bug_report,
                                color: Colors.purple,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TranslatedText(
                                  disease,
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                    color: mainText,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // Crop
                          Row(
                            children: [
                              const Icon(
                                Icons.eco,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TranslatedText(
                                  "Crop: $crop",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: subText,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Accuracy + Risk
                          Row(
                            children: [
                              const Icon(
                                Icons.track_changes,
                                color: Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TranslatedText(
                                  "Accuracy: ${accuracy.toStringAsFixed(2)}%",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: subText,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: riskColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: TranslatedText(
                                  risk,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Icon(
                                Icons.warning,
                                color: riskColor,
                              ),
                              const SizedBox(width: 8),
                              TranslatedText(
                                "$risk Risk Level",
                                style: TextStyle(
                                  color: riskColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // =========================
                    // DESCRIPTION
                    // =========================
                    TranslatedText(
                      "Description",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: mainText,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: sectionBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: TranslatedText(
                        description,
                        style: TextStyle(
                          height: 1.5,
                          color: subText,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // =========================
                    // TREATMENT
                    // =========================
                    TranslatedText(
                      "Recommended Treatment",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: mainText,
                      ),
                    ),

                    const SizedBox(height: 12),

                    ...treatment.map<Widget>((t) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TranslatedText(
                                t.toString(),
                                style: TextStyle(
                                  height: 1.4,
                                  color: subText,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),

                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // =========================
      // FIXED BOTTOM BUTTONS
      // =========================
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: BoxDecoration(
            color: bottomBg,
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.35)
                    : Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        isDark ? Colors.green.shade300 : Colors.green,
                    side: BorderSide(
                      color: isDark ? Colors.green.shade700 : Colors.green,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: TranslatedText(
                    "New Detection",
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: () {
                    _saveTreatment(
                      context: context,
                      disease: disease,
                      crop: crop,
                      risk: risk,
                      description: description,
                      treatment: treatment,
                      accuracy: accuracy,
                    );
                  },
                  child: TranslatedText(
                    "Save Treatment",
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
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