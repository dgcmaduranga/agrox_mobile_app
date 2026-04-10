import 'package:flutter/material.dart';
import '../../widgests/translated_text.dart';

class DiseaseDetailPage extends StatelessWidget {
  final Map disease;

  const DiseaseDetailPage({super.key, required this.disease});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F8),

      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: TranslatedText(
          "${disease['name']} (${disease['crop']})",
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      body: Column(
        children: [

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 180,
                width: double.infinity,
                child: Image.asset(
                  disease['image'],
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: isDark
                        ? []
                        : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            )
                          ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      ///  OVERVIEW
                      TranslatedText(
                        "Overview",
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 8),

                      _row(context, "Crop:", disease['crop']),
                      _row(context, "Disease:", disease['name']),

                      const SizedBox(height: 16),

                      TranslatedText(
                        disease['description'],
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: isDark
                              ? Colors.grey[300]
                              : Colors.grey[700],
                        ),
                      ),

                      const SizedBox(height: 20),

                      _sectionTitle(context, "Symptoms"),
                      ..._buildList(disease['symptoms']),

                      const SizedBox(height: 16),

                      _sectionTitle(context, "Causes"),
                      ..._buildList(disease['causes']),

                      const SizedBox(height: 16),

                      _sectionTitle(context, "⚠ High Risk Treatments"),
                      ..._buildList(disease['highRiskTreatments']),

                      const SizedBox(height: 16),
                      _sectionTitle(context, "✅ Low Risk Treatments"),
                      ..._buildList(disease['lowRiskTreatments']),

                      const SizedBox(height: 16),
                      _sectionTitle(context, "Prevention"),
                      ..._buildList(disease['prevention']),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                  child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/home',
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: TranslatedText(
                    "Back to Home",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          TranslatedText(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 6),
          Expanded(child: TranslatedText(value)),
        ],
      ),
    );
  }
  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: TranslatedText(
        title,
        style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
  List<Widget> _buildList(List list) {
    return list.map<Widget>((e) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: TranslatedText(
          "• $e",
          style: const TextStyle(height: 1.4),
        ),
      );
    }).toList();
  }
}