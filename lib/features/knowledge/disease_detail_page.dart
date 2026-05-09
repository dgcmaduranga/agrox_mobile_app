import 'package:flutter/material.dart';
import '../../widgests/translated_text.dart';

class DiseaseDetailPage extends StatelessWidget {
  final Map disease;

  const DiseaseDetailPage({super.key, required this.disease});

  // ===============================
  // APP THEME COLORS
  // ===============================
  static const Color kDarkGreen = Color(0xFF0B5D1E);
  static const Color kMainGreen = Color(0xFF1B7F35);
  static const Color kLightGreen = Color(0xFFEAF7EE);

  String _safeText(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  List _safeList(dynamic value) {
    if (value is List) return value;
    return [];
  }

  String _displayCrop(String crop) {
    final c = crop.toLowerCase().trim();

    if (c == 'rice' || c == 'paddy') return 'Rice Leaf';
    if (c == 'tea') return 'Tea Leaf';
    if (c == 'coconut') return 'Coconut Leaf';

    if (crop.trim().isEmpty) return 'Crop';

    return crop[0].toUpperCase() + crop.substring(1);
  }

  IconData _cropIcon(String crop) {
    final c = crop.toLowerCase().trim();

    if (c == 'rice' || c == 'paddy') return Icons.grass_rounded;
    if (c == 'tea') return Icons.eco_rounded;
    if (c == 'coconut') return Icons.park_rounded;

    return Icons.spa_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final String diseaseName = _safeText(
      disease['name'],
      fallback: 'Disease Detail',
    );

    final String crop = _safeText(
      disease['crop'],
      fallback: 'Crop',
    );

    final String imagePath = _safeText(disease['image']);

    final String description = _safeText(
      disease['description'],
      fallback: 'No description available.',
    );

    final Color scaffoldBg =
        isDark ? const Color(0xFF0B0F14) : const Color(0xFFF6F8F5);

    final Color cardBg = isDark ? const Color(0xFF161B22) : Colors.white;

    final Color mainText = isDark ? Colors.white : const Color(0xFF102014);

    final Color subText = isDark ? Colors.white60 : Colors.black54;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ===============================
            // FIXED GREEN HEADER CARD
            // ===============================
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
                        Navigator.pop(context);
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
                      child: Icon(
                        _cropIcon(crop),
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
                            diseaseName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          TranslatedText(
                            "${_displayCrop(crop)} disease detail 🌱",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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

            // ===============================
            // FIXED SMALL IMAGE HEADER
            // ===============================
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Container(
                width: double.infinity,
                height: 155,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(
                        isDark ? 0.24 : 0.08,
                      ),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(
                        tag: imagePath + diseaseName,
                        child: imagePath.isNotEmpty
                            ? Image.asset(
                                imagePath,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _imageFallback(isDark);
                                },
                              )
                            : _imageFallback(isDark),
                      ),

                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.04),
                              Colors.black.withOpacity(0.58),
                            ],
                          ),
                        ),
                      ),

                      Positioned(
                        left: 14,
                        right: 14,
                        bottom: 12,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.25),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _cropIcon(crop),
                                    size: 13,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 5),
                                  TranslatedText(
                                    _displayCrop(crop),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 7),
                            TranslatedText(
                              diseaseName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight: FontWeight.w900,
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ===============================
            // SCROLL CONTENT ONLY
            // ===============================
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ===============================
                    // OVERVIEW CARD
                    // ===============================
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: _cardDecoration(isDark, cardBg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionHeader(
                            icon: Icons.info_rounded,
                            title: 'Overview',
                            isDark: isDark,
                            mainText: mainText,
                          ),
                          const SizedBox(height: 12),
                          _infoRow(
                            context,
                            icon: Icons.spa_rounded,
                            title: 'Crop',
                            value: _displayCrop(crop),
                            isDark: isDark,
                            mainText: mainText,
                            subText: subText,
                          ),
                          const SizedBox(height: 8),
                          _infoRow(
                            context,
                            icon: Icons.coronavirus_rounded,
                            title: 'Disease',
                            value: diseaseName,
                            isDark: isDark,
                            mainText: mainText,
                            subText: subText,
                          ),
                          const SizedBox(height: 14),
                          TranslatedText(
                            description,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.55,
                              color: isDark ? Colors.white70 : Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    _sectionCard(
                      isDark: isDark,
                      cardBg: cardBg,
                      mainText: mainText,
                      subText: subText,
                      icon: Icons.warning_amber_rounded,
                      title: 'Symptoms',
                      items: _safeList(disease['symptoms']),
                    ),

                    const SizedBox(height: 12),

                    _sectionCard(
                      isDark: isDark,
                      cardBg: cardBg,
                      mainText: mainText,
                      subText: subText,
                      icon: Icons.bug_report_rounded,
                      title: 'Causes',
                      items: _safeList(disease['causes']),
                    ),

                    const SizedBox(height: 12),

                    _sectionCard(
                      isDark: isDark,
                      cardBg: cardBg,
                      mainText: mainText,
                      subText: subText,
                      icon: Icons.priority_high_rounded,
                      title: 'High Risk Treatments',
                      items: _safeList(disease['highRiskTreatments']),
                      danger: true,
                    ),

                    const SizedBox(height: 12),

                    _sectionCard(
                      isDark: isDark,
                      cardBg: cardBg,
                      mainText: mainText,
                      subText: subText,
                      icon: Icons.health_and_safety_rounded,
                      title: 'Low Risk Treatments',
                      items: _safeList(disease['lowRiskTreatments']),
                    ),

                    const SizedBox(height: 12),

                    _sectionCard(
                      isDark: isDark,
                      cardBg: cardBg,
                      mainText: mainText,
                      subText: subText,
                      icon: Icons.shield_rounded,
                      title: 'Prevention',
                      items: _safeList(disease['prevention']),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===============================
  // IMAGE FALLBACK
  // ===============================
  Widget _imageFallback(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF161B22) : kLightGreen,
      child: const Center(
        child: Icon(
          Icons.eco_rounded,
          color: kDarkGreen,
          size: 54,
        ),
      ),
    );
  }

  // ===============================
  // CARD DECORATION
  // ===============================
  BoxDecoration _cardDecoration(bool isDark, Color cardBg) {
    return BoxDecoration(
      color: cardBg,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(
        color: isDark
            ? Colors.white.withOpacity(0.06)
            : kDarkGreen.withOpacity(0.06),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(isDark ? 0.18 : 0.045),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  // ===============================
  // SECTION HEADER
  // ===============================
  Widget _sectionHeader({
    required IconData icon,
    required String title,
    required bool isDark,
    required Color mainText,
    bool danger = false,
  }) {
    final Color iconColor = danger ? Colors.red : kDarkGreen;
    final Color bgColor = danger ? Colors.red.withOpacity(0.10) : kLightGreen;

    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: isDark ? iconColor.withOpacity(0.16) : bgColor,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 21,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TranslatedText(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: mainText,
            ),
          ),
        ),
      ],
    );
  }

  // ===============================
  // INFO ROW
  // ===============================
  Widget _infoRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required bool isDark,
    required Color mainText,
    required Color subText,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : kLightGreen,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: kDarkGreen,
            size: 18,
          ),
          const SizedBox(width: 9),
          TranslatedText(
            '$title:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: subText,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TranslatedText(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: mainText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===============================
  // SECTION CARD
  // ===============================
  Widget _sectionCard({
    required bool isDark,
    required Color cardBg,
    required Color mainText,
    required Color subText,
    required IconData icon,
    required String title,
    required List items,
    bool danger = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(isDark, cardBg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: icon,
            title: title,
            isDark: isDark,
            mainText: mainText,
            danger: danger,
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            TranslatedText(
              'No information available',
              style: TextStyle(
                color: subText,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            )
          else
            ...items.map<Widget>((item) {
              return _bulletItem(
                item.toString(),
                isDark: isDark,
                subText: subText,
                danger: danger,
              );
            }).toList(),
        ],
      ),
    );
  }

  // ===============================
  // BULLET ITEM
  // ===============================
  Widget _bulletItem(
    String text, {
    required bool isDark,
    required Color subText,
    bool danger = false,
  }) {
    final Color dotColor = danger ? Colors.red : kDarkGreen;

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 7),
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TranslatedText(
              text,
              style: TextStyle(
                height: 1.45,
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: subText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}