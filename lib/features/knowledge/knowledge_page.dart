import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/api_service.dart';
import 'disease_detail_page.dart';

class KnowledgePage extends StatefulWidget {
  const KnowledgePage({super.key});

  @override
  State<KnowledgePage> createState() => _KnowledgePageState();
}

class _KnowledgePageState extends State<KnowledgePage> {
  List<dynamic> allDiseases = [];
  List<dynamic> filteredDiseases = [];

  String selectedCrop = 'rice';
  String searchText = '';

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    try {
      final uri = Uri.parse('${ApiService.baseUrl}/diseases');
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() {
          allDiseases = (data is List) ? data : [];
          applyFilter();
        });
      } else {
        setState(() {
          allDiseases = [];
          filteredDiseases = [];
        });
      }
    } catch (e) {
      print("Error loading diseases: $e");
    }
  }

  void applyFilter() {
    List temp =
        allDiseases.where((d) => d['crop'] == selectedCrop).toList();

    if (searchText.isNotEmpty) {
      temp = temp
          .where((d) => d['name']
              .toString()
              .toLowerCase()
              .contains(searchText.toLowerCase()))
          .toList();
    }

    setState(() {
      filteredDiseases = temp;
    });
  }

  Widget buildTab(
      String crop, String label, IconData icon, bool isDark) {
    bool isSelected = selectedCrop == crop;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCrop = crop;
          applyFilter();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.green
              : (isDark
                  ? const Color(0xFF2C2C2C)
                  : Colors.grey.shade200),
          borderRadius: BorderRadius.circular(30),
          boxShadow: isSelected && !isDark
              ? [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 16,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white : Colors.black)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white : Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F8),

      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text('Knowledge Hub'),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E1E1E)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                style: TextStyle(
                    color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  hintText: 'Search diseases...',
                  hintStyle: TextStyle(
                      color: isDark
                          ? Colors.grey[400]
                          : Colors.grey[600]),
                  prefixIcon: Icon(Icons.search,
                      color: isDark
                          ? Colors.grey[400]
                          : Colors.grey[700]),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  searchText = value;
                  applyFilter();
                },
              ),
            ),

            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                buildTab('rice', 'Rice', Icons.grain, isDark),
                buildTab('tea', 'Tea', Icons.local_cafe, isDark),
                buildTab('coconut', 'Coconut', Icons.park, isDark),
              ],
            ),

            const SizedBox(height: 16),

            Expanded(
              child: ListView.builder(
                itemCount: filteredDiseases.length,
                itemBuilder: (context, index) {
                  final disease = filteredDiseases[index];

                  return TweenAnimationBuilder(
                    duration:
                        Duration(milliseconds: 300 + (index * 50)),
                    tween: Tween<double>(begin: 0, end: 1),
                    builder: (context, double value, child) {
                      return Transform.translate(
                        offset: Offset(0, 30 * (1 - value)),
                        child: Opacity(opacity: value, child: child),
                      );
                    },
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                DiseaseDetailPage(disease: disease),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E1E1E)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: isDark
                              ? []
                              : [
                                  BoxShadow(
                                    color: Colors.black
                                        .withOpacity(0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                disease['image'],
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    disease['name'],
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    disease['description'],
                                    maxLines: 2,
                                    overflow:
                                        TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios,
                                size: 16,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600]),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}