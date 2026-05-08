import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../../services/api_service.dart';
import 'disease_detail_page.dart';
import '../../widgests/translated_text.dart';

class KnowledgePage extends StatefulWidget {
  const KnowledgePage({super.key});

  @override
  State<KnowledgePage> createState() => _KnowledgePageState();
}

// ===============================
// APP THEME COLORS
// ===============================
const Color kDarkGreen = Color(0xFF0B5D1E);
const Color kMainGreen = Color(0xFF1B7F35);
const Color kLightGreen = Color(0xFFEAF7EE);

class _KnowledgePageState extends State<KnowledgePage> {
  List<dynamic> allDiseases = [];
  List<dynamic> filteredDiseases = [];

  String selectedCrop = 'paddy';
  String searchText = '';

  bool isLoading = true;
  bool usingOfflineData = false;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  String normalizeCrop(String crop) {
    if (crop == "paddy") return "rice";
    return crop;
  }

  // ===============================
  // LOAD DATA
  // Backend first. If backend fails, load local diseases.json.
  // ===============================
  Future<void> loadData() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      usingOfflineData = false;
    });

    try {
      final uri = Uri.parse('${ApiService.baseUrl}/diseases');
      final res = await http.get(uri).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = json.decode(res.body);

        if (!mounted) return;

        setState(() {
          allDiseases = (data is List) ? data : [];
          usingOfflineData = false;
          isLoading = false;
        });

        applyFilter();
        return;
      }

      await loadOfflineData();
    } catch (e) {
      debugPrint("Backend disease load failed. Loading offline JSON: $e");
      await loadOfflineData();
    }
  }

  // ===============================
  // OFFLINE JSON LOAD
  // diseases.json must be added to pubspec.yaml assets
  // ===============================
  Future<void> loadOfflineData() async {
    try {
      final String jsonString = await rootBundle.loadString('diseases.json');
      final data = json.decode(jsonString);

      if (!mounted) return;

      setState(() {
        allDiseases = (data is List) ? data : [];
        usingOfflineData = true;
        isLoading = false;
      });

      applyFilter();
    } catch (e) {
      debugPrint("Offline diseases.json load error: $e");

      if (!mounted) return;

      setState(() {
        allDiseases = [];
        filteredDiseases = [];
        usingOfflineData = false;
        isLoading = false;
      });
    }
  }

  void applyFilter() {
    final backendCrop = normalizeCrop(selectedCrop);

    List temp = allDiseases.where((d) {
      final crop = d['crop']?.toString().toLowerCase().trim() ?? '';
      return crop == backendCrop;
    }).toList();

    if (searchText.isNotEmpty) {
      temp = temp.where((d) {
        final name = d['name']?.toString().toLowerCase() ?? '';
        final desc = d['description']?.toString().toLowerCase() ?? '';
        final query = searchText.toLowerCase();

        return name.contains(query) || desc.contains(query);
      }).toList();
    }

    if (!mounted) return;

    setState(() {
      filteredDiseases = temp;
    });
  }

  IconData _cropIcon(String crop) {
    switch (crop) {
      case 'paddy':
      case 'rice':
        return Icons.grass_rounded;
      case 'tea':
        return Icons.eco_rounded;
      case 'coconut':
        return Icons.park_rounded;
      default:
        return Icons.spa_rounded;
    }
  }

  String _displayCropLabel(String crop) {
    switch (crop) {
      case 'paddy':
      case 'rice':
        return 'Rice Leaf';
      case 'tea':
        return 'Tea Leaf';
      case 'coconut':
        return 'Coconut Leaf';
      default:
        return _titleCase(crop);
    }
  }

  Widget buildTab(
    String crop,
    Widget labelWidget,
    IconData icon,
    bool isDark,
  ) {
    final bool isSelected = selectedCrop == crop;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedCrop = crop;
          });
          applyFilter();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF064E1A),
                      Color(0xFF0B5D1E),
                      Color(0xFF1B7F35),
                    ],
                  )
                : null,
            color: isSelected
                ? null
                : (isDark ? const Color(0xFF161B22) : Colors.white),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? kMainGreen
                  : (isDark
                      ? Colors.white.withOpacity(0.06)
                      : kDarkGreen.withOpacity(0.08)),
              width: isSelected ? 1.4 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? kDarkGreen.withOpacity(0.20)
                    : Colors.black.withOpacity(isDark ? 0.16 : 0.035),
                blurRadius: isSelected ? 10 : 7,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 17,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : kDarkGreen),
              ),
              const SizedBox(height: 4),
              DefaultTextStyle.merge(
                style: TextStyle(
                  fontSize: 11.2,
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white : const Color(0xFF102014)),
                ),
                child: Center(child: labelWidget),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color scaffoldBg =
        isDark ? const Color(0xFF0B0F14) : const Color(0xFFF6F8F5);

    final Color cardBg = isDark ? const Color(0xFF161B22) : Colors.white;

    final Color mainText = isDark ? Colors.white : const Color(0xFF102014);

    final Color subText = isDark ? Colors.white60 : Colors.black54;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              child: _premiumTopHeader(
                context: context,
                isDark: isDark,
              ),
            ),

            const SizedBox(height: 12),

            // ===============================
            // SEARCH
            // ===============================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.06)
                        : kDarkGreen.withOpacity(0.08),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.16 : 0.035),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  style: TextStyle(
                    color: mainText,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search diseases...',
                    hintStyle: TextStyle(
                      color: subText,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: 22,
                      color: isDark ? Colors.white54 : kDarkGreen,
                    ),
                    suffixIcon: searchText.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.close_rounded,
                              size: 20,
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                            onPressed: () {
                              setState(() {
                                searchText = '';
                              });
                              applyFilter();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) {
                    searchText = value;
                    applyFilter();
                  },
                ),
              ),
            ),

            const SizedBox(height: 10),

            // ===============================
            // TABS
            // ===============================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  buildTab(
                    'paddy',
                    const TranslatedText('Rice Leaf'),
                    _cropIcon('paddy'),
                    isDark,
                  ),
                  buildTab(
                    'tea',
                    const TranslatedText('Tea Leaf'),
                    _cropIcon('tea'),
                    isDark,
                  ),
                  buildTab(
                    'coconut',
                    const TranslatedText('Coconut Leaf'),
                    _cropIcon('coconut'),
                    isDark,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // ===============================
            // LIST
            // ===============================
            Expanded(
              child: isLoading
                  ? Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.06)
                                : kDarkGreen.withOpacity(0.08),
                          ),
                        ),
                        child: const SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(
                            color: kDarkGreen,
                            strokeWidth: 3,
                          ),
                        ),
                      ),
                    )
                  : filteredDiseases.isEmpty
                      ? _emptyState(isDark, mainText, subText)
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                          itemCount: filteredDiseases.length,
                          itemBuilder: (context, index) {
                            final disease = filteredDiseases[index];

                            return TweenAnimationBuilder(
                              duration: Duration(
                                milliseconds: 250 + (index * 35),
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
                              child: _diseaseCard(
                                disease: disease,
                                isDark: isDark,
                                cardBg: cardBg,
                                mainText: mainText,
                                subText: subText,
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // ===============================
  // TOP HEADER
  // ===============================
  Widget _premiumTopHeader({
    required BuildContext context,
    required bool isDark,
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
              Icons.local_library_rounded,
              color: Colors.white,
              size: 27,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TranslatedText(
                  "Knowledge Hub",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                const TranslatedText(
                  "Crop disease library 🌱",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (usingOfflineData) ...[
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.10),
                      ),
                    ),
                    child: const Text(
                      'Offline data',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          GestureDetector(
            onTap: loadData,
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
                Icons.refresh_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===============================
  // EMPTY STATE
  // ===============================
  Widget _emptyState(bool isDark, Color mainText, Color subText) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161B22) : kLightGreen,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: kDarkGreen.withOpacity(0.10),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.search_off_rounded,
                color: kDarkGreen,
                size: 34,
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TranslatedText(
                "No diseases found",
                style: TextStyle(
                  color: mainText,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 5),
            Center(
              child: TranslatedText(
                "Try another crop or search keyword",
                style: TextStyle(
                  color: subText,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===============================
  // DISEASE CARD
  // ===============================
  Widget _diseaseCard({
    required dynamic disease,
    required bool isDark,
    required Color cardBg,
    required Color mainText,
    required Color subText,
  }) {
    final String imagePath = disease['image']?.toString() ?? '';
    final String diseaseName = disease['name']?.toString() ?? '';
    final String description = disease['description']?.toString() ?? '';
    final String crop = disease['crop']?.toString() ?? selectedCrop;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DiseaseDetailPage(disease: disease),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(19),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : kDarkGreen.withOpacity(0.06),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.16 : 0.04),
              blurRadius: 11,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Hero(
              tag: imagePath + diseaseName,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  width: 72,
                  height: 72,
                  color: isDark ? const Color(0xFF0F1720) : kLightGreen,
                  child: imagePath.isNotEmpty
                      ? Image.asset(
                          imagePath,
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.eco_rounded,
                              color: kDarkGreen,
                              size: 32,
                            );
                          },
                        )
                      : const Icon(
                          Icons.eco_rounded,
                          color: kDarkGreen,
                          size: 32,
                        ),
                ),
              ),
            ),

            const SizedBox(width: 11),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: kLightGreen,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _cropIcon(crop == 'rice' ? 'paddy' : crop),
                          size: 11,
                          color: kDarkGreen,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _displayCropLabel(crop),
                          style: const TextStyle(
                            color: kDarkGreen,
                            fontSize: 9.8,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 6),

                  TranslatedText(
                    diseaseName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: mainText,
                      height: 1.05,
                    ),
                  ),

                  const SizedBox(height: 4),

                  TranslatedText(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: subText,
                      fontSize: 11.8,
                      fontWeight: FontWeight.w500,
                      height: 1.22,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            Container(
              width: 31,
              height: 31,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.06) : kLightGreen,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 13,
                color: isDark ? Colors.white60 : kDarkGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _titleCase(String value) {
    final words = value
        .replaceAll('_', ' ')
        .trim()
        .split(' ')
        .where((w) => w.trim().isNotEmpty)
        .toList();

    if (words.isEmpty) return value;

    return words.map((word) {
      final w = word.trim();
      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    }).join(' ');
  }
}