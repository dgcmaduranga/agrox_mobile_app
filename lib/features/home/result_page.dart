import 'package:flutter/material.dart';

import '../../services/saved_treatment_service.dart';

class ResultPage extends StatelessWidget {
  final Map<String, dynamic> data;

  const ResultPage({super.key, required this.data});

  Future<void> _saveTreatment({
    required BuildContext context,
    required String disease,
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
        crop: data["crop"]?.toString() ?? data["selectedCrop"]?.toString() ?? "Unknown Crop",
        riskLevel: risk,
        description: description,
        treatments: treatmentList,
        accuracy: accuracy,
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Treatment saved successfully"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Failed to save treatment: $e"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // =========================
    // DARK MODE COLORS
    // =========================
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color scaffoldBg =
        isDark ? const Color(0xFF0B0F14) : const Color(0xFFF8F9FA);

    final Color cardBg =
        isDark ? const Color(0xFF161B22) : Colors.grey.shade100;

    final Color sectionBg =
        isDark ? const Color(0xFF161B22) : Colors.grey.shade50;

    final Color mainText = isDark ? Colors.white : Colors.black87;

    final Color subText = isDark ? Colors.white70 : Colors.black87;

    final Color borderColor =
        isDark ? Colors.white.withOpacity(0.08) : Colors.transparent;

    final Color shadowColor =
        isDark ? Colors.black.withOpacity(0.28) : Colors.black12;

    // =========================
    // SAFE DATA HANDLING 🔥
    // =========================
    final String disease = data["disease"]?.toString() ?? "Unknown Disease";

    final double accuracy =
        (data["accuracy"] is num) ? (data["accuracy"] as num).toDouble() : 0.0;

    final String risk = data["risk"]?.toString() ?? "Low";

    final String description =
        data["description"]?.toString() ?? "No detailed data found.";

    final List<dynamic> treatment =
        (data["treatment"] is List && data["treatment"].isNotEmpty)
            ? data["treatment"]
            : ["No recommendations available"];

    final bool isHighRisk = risk.toLowerCase() == "high";

    final Color riskColor = isHighRisk ? Colors.red : Colors.green;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: mainText),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: mainText,
          ),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/home',
              (route) => false,
            );
          },
        ),
        title: Text(
          "Detection Result",
          style: TextStyle(
            color: mainText,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =========================
              // 🔥 RESULT CARD
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
                    )
                  ],
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // DISEASE
                    Row(
                      children: [
                        const Icon(Icons.bug_report, color: Colors.purple),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
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

                    // ACCURACY + RISK
                    Row(
                      children: [
                        const Icon(Icons.track_changes, color: Colors.red),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
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
                          child: Text(
                            risk,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      ],
                    ),

                    const SizedBox(height: 12),

                    // RISK TEXT
                    Row(
                      children: [
                        Icon(
                          Icons.warning,
                          color: riskColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
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

              const SizedBox(height: 25),

              // =========================
              // 📄 DESCRIPTION
              // =========================
              Text(
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
                child: Text(
                  description,
                  style: TextStyle(
                    height: 1.5,
                    color: subText,
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // =========================
              // 💊 TREATMENT
              // =========================
              Text(
                "Recommended Treatment",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: mainText,
                ),
              ),

              const SizedBox(height: 10),

              ...treatment.map<Widget>((t) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          t.toString(),
                          style: TextStyle(
                            height: 1.4,
                            color: subText,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),

              const SizedBox(height: 30),

              // =========================
              // 🔘 BUTTONS
              // =========================
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            isDark ? Colors.green.shade300 : Colors.green,
                        side: BorderSide(
                          color:
                              isDark ? Colors.green.shade700 : Colors.green,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text("New Detection"),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        _saveTreatment(
                          context: context,
                          disease: disease,
                          risk: risk,
                          description: description,
                          treatment: treatment,
                          accuracy: accuracy,
                        );
                      },
                      child: const Text("Save Treatment"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}