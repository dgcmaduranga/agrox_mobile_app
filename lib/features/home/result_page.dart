import 'package:flutter/material.dart';

class ResultPage extends StatelessWidget {
  final Map<String, dynamic> data;

  const ResultPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // =========================
    // SAFE DATA HANDLING 🔥
    // =========================
    final String disease =
        data["disease"]?.toString() ?? "Unknown Disease";

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

    return Scaffold(
      appBar: AppBar(
        title: const Text("Detection Result"),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
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
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
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
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
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
                        Text(
                          "Accuracy: ${accuracy.toStringAsFixed(2)}%",
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),

                        const SizedBox(width: 12),

                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isHighRisk ? Colors.red : Colors.green,
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
                          color: isHighRisk ? Colors.red : Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "$risk Risk Level",
                          style: TextStyle(
                            color: isHighRisk ? Colors.red : Colors.green,
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
              const Text(
                "Description",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  description,
                  style: const TextStyle(height: 1.5),
                ),
              ),

              const SizedBox(height: 25),

              // =========================
              // 💊 TREATMENT
              // =========================
              const Text(
                "Recommended Treatment",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              ...treatment.map<Widget>((t) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle,
                          color: Colors.green, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          t.toString(),
                          style: const TextStyle(height: 1.4),
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
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
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
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () =>
                          Navigator.popUntil(context, (r) => r.isFirst),
                      child: const Text("Back to Home"),
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