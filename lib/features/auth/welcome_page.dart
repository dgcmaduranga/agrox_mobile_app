import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/language_provider.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

// ===============================
// APP THEME COLORS
// ===============================
const Color kDarkGreen = Color(0xFF0B5D1E);
const Color kMainGreen = Color(0xFF1B7F35);
const Color kLightGreen = Color(0xFFEAF8E7);

class _WelcomePageState extends State<WelcomePage> {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentIndex == 2) {
      Navigator.pushNamed(context, '/login');
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _skip() {
    _controller.animateToPage(
      2,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeInOutCubic,
    );
  }

  bool getIsDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  Color getBg(BuildContext context) {
    return getIsDark(context) ? const Color(0xFF0B0F14) : Colors.white;
  }

  Color getCard(BuildContext context) {
    return getIsDark(context) ? const Color(0xFF161B22) : Colors.white;
  }

  Color getText(BuildContext context) {
    return getIsDark(context) ? Colors.white : const Color(0xFF102014);
  }

  Color getSubText(BuildContext context) {
    return getIsDark(context) ? Colors.white60 : Colors.black54;
  }

  // ===============================
  // DOT
  // ===============================
  Widget _dot(bool active) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      width: active ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        gradient: active
            ? const LinearGradient(
                colors: [
                  Color(0xFF064E1A),
                  Color(0xFF1B7F35),
                ],
              )
            : null,
        color: active ? null : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(30),
      ),
    );
  }

  // ===============================
  // BRAND HEADER
  // ===============================
  Widget _brandHeader({
    required bool isSinhala,
    required IconData icon,
    required String smallTitle,
    required String mainTitle,
    bool showSkip = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 14),
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
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: kDarkGreen.withOpacity(0.24),
            blurRadius: 20,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withOpacity(0.20),
              ),
            ),
            child: const Icon(
              Icons.eco_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  smallTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.72),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  mainTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.2,
                    height: 1.05,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          if (showSkip)
            GestureDetector(
              onTap: _skip,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.24),
                  ),
                ),
                child: Text(
                  isSinhala ? "ඉවතට" : "Skip",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            )
          else
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.18),
                ),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 22,
              ),
            ),
        ],
      ),
    );
  }

  // ===============================
  // CONTENT PAGE
  // ===============================
  Widget _welcomeContentPage({
    required bool isSinhala,
    required String titleEN,
    required String titleSI,
    required String subtitleEN,
    required String subtitleSI,
    required String image,
    required IconData icon,
    required String badgeEN,
    required String badgeSI,
    required bool showSkip,
  }) {
    final bool isDark = getIsDark(context);
    final Color textColor = getText(context);
    final Color subText = getSubText(context);
    final Color cardColor = getCard(context);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 128),
      child: Column(
        children: [
          _brandHeader(
            isSinhala: isSinhala,
            icon: icon,
            smallTitle: isSinhala ? "ආයුබෝවන්" : "Welcome to",
            mainTitle: "AgroX",
            showSkip: showSkip,
          ),

          const SizedBox(height: 24),

          // ===============================
          // TEXT ABOVE IMAGE
          // ===============================
          Text(
            isSinhala ? titleSI : titleEN,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: textColor,
              height: 1.16,
              letterSpacing: -0.2,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            isSinhala ? subtitleSI : subtitleEN,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: subText,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 22),

          // ===============================
          // IMAGE CARD
          // ===============================
          Container(
            width: double.infinity,
            height: 305,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(34),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.06)
                    : kDarkGreen.withOpacity(0.06),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.22 : 0.055),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Stack(
                children: [
                  Positioned(
                    top: -45,
                    right: -42,
                    child: _softCircle(
                      size: 150,
                      opacity: isDark ? 0.10 : 0.07,
                    ),
                  ),
                  Positioned(
                    bottom: -55,
                    left: -50,
                    child: _softCircle(
                      size: 165,
                      opacity: isDark ? 0.09 : 0.06,
                    ),
                  ),

                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? kDarkGreen.withOpacity(0.18)
                              : kLightGreen,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: kDarkGreen.withOpacity(0.08),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              icon,
                              color: kDarkGreen,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isSinhala ? badgeSI : badgeEN,
                              style: TextStyle(
                                color: isDark
                                    ? Colors.green.shade300
                                    : kDarkGreen,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      Expanded(
                        child: Center(
                          child: Image.asset(
                            image,
                            fit: BoxFit.contain,
                            width: double.infinity,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===============================
  // FINAL PAGE
  // ===============================
  Widget _finalPage(bool isSinhala) {
    final bool isDark = getIsDark(context);
    final Color textColor = getText(context);
    final Color subText = getSubText(context);
    final Color cardColor = getCard(context);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 128),
      child: Column(
        children: [
          // ===============================
          // GREEN CARD AT TOP
          // ===============================
          _brandHeader(
            isSinhala: isSinhala,
            icon: Icons.verified_rounded,
            smallTitle: isSinhala
                ? "ඔබේ smart farming assistant"
                : "Your smart farming assistant",
            mainTitle: "AgroX",
            showSkip: false,
          ),

          const SizedBox(height: 24),

          // ===============================
          // TEXT ABOVE IMAGE
          // ===============================
          Text(
            isSinhala ? "AgroX භාවිතා කරන්න" : "Start with AgroX",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w900,
              color: textColor,
              height: 1.15,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            isSinhala
                ? "ඔබේ වගාව සුරක්ෂිතව කළමනාකරණය කිරීමට දැන් ආරම්භ කරන්න."
                : "Manage crop health, weather risks, and farming guidance in one smart app.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.7,
              color: subText,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 22),

          // ===============================
          // FINAL IMAGE CARD
          // ===============================
          Container(
            width: double.infinity,
            height: 245,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(34),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.06)
                    : kDarkGreen.withOpacity(0.06),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.22 : 0.055),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Stack(
                children: [
                  Positioned(
                    top: -45,
                    right: -40,
                    child: _softCircle(
                      size: 150,
                      opacity: isDark ? 0.10 : 0.07,
                    ),
                  ),
                  Positioned(
                    bottom: -55,
                    left: -48,
                    child: _softCircle(
                      size: 165,
                      opacity: isDark ? 0.09 : 0.06,
                    ),
                  ),
                  Center(
                    child: Image.asset(
                      'assets/images/welcome.png',
                      fit: BoxFit.contain,
                      width: double.infinity,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 22),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/signup');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kDarkGreen,
                foregroundColor: Colors.white,
                elevation: 8,
                shadowColor: kDarkGreen.withOpacity(0.30),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              child: Text(
                isSinhala ? "ලියාපදිංචි වන්න" : "Create Account",
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
              style: OutlinedButton.styleFrom(
                backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
                side: BorderSide(
                  color: isDark
                      ? Colors.green.shade700
                      : kDarkGreen.withOpacity(0.50),
                  width: 1.3,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              child: Text(
                isSinhala ? "පිවිසෙන්න" : "Login",
                style: TextStyle(
                  color: isDark ? Colors.green.shade300 : kDarkGreen,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===============================
  // BUILD
  // ===============================
  @override
  Widget build(BuildContext context) {
    final isSinhala = context.watch<LanguageProvider>().isSinhala;
    final bool isDark = getIsDark(context);

    return Scaffold(
      backgroundColor: getBg(context),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                color: getBg(context),
              ),
            ),

            Positioned(
              top: -95,
              right: -80,
              child: _softCircle(
                size: 220,
                opacity: isDark ? 0.10 : 0.055,
              ),
            ),

            Positioned(
              bottom: 38,
              left: -105,
              child: _softCircle(
                size: 240,
                opacity: isDark ? 0.09 : 0.050,
              ),
            ),

            PageView(
              controller: _controller,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              children: [
                _welcomeContentPage(
                  isSinhala: isSinhala,
                  titleEN: "Smart farming support in one app",
                  titleSI: "කෘෂිකර්මාන්තයට බුද්ධිමත් සහය එකම app එකකින්",
                  subtitleEN:
                      "Detect crop diseases, track weather risks, ask AgroX AI, and explore farming knowledge easily.",
                  subtitleSI:
                      "වගා රෝග හඳුනාගෙන, කාලගුණ අවදානම් දැනගෙන, AgroX AIගෙන් උපදෙස් ලබාගෙන, කෘෂි දැනුම පහසුවෙන් බලන්න.",
                  image: 'assets/images/welcome.png',
                  icon: Icons.spa_rounded,
                  badgeEN: "Smart agriculture",
                  badgeSI: "බුද්ධිමත් කෘෂිකර්මය",
                  showSkip: true,
                ),

                _welcomeContentPage(
                  isSinhala: isSinhala,
                  titleEN: "AI disease detection for tea, rice, and coconut",
                  titleSI: "තේ, වී සහ පොල් සඳහා AI රෝග හඳුනාගැනීම",
                  subtitleEN:
                      "Upload a leaf image, detect possible diseases, and get useful solutions to protect your crop.",
                  subtitleSI:
                      "පත්‍ර රූපයක් upload කර ඇති විය හැකි රෝග හඳුනාගෙන, ඔබේ වගාව ආරක්ෂා කරගැනීමට අවශ්‍ය විසඳුම් ලබාගන්න.",
                  image: 'assets/images/welcome2.png',
                  icon: Icons.health_and_safety_rounded,
                  badgeEN: "AI disease detection",
                  badgeSI: "AI රෝග හඳුනාගැනීම",
                  showSkip: false,
                ),

                _finalPage(isSinhala),
              ],
            ),

            // ===============================
            // BOTTOM CONTROLS
            // ===============================
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _dot(_currentIndex == 0),
                      _dot(_currentIndex == 1),
                      _dot(_currentIndex == 2),
                    ],
                  ),

                  const SizedBox(height: 18),

                  if (_currentIndex != 2)
                    GestureDetector(
                      onTap: _nextPage,
                      child: Container(
                        width: 60,
                        height: 60,
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
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: kDarkGreen.withOpacity(0.34),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 27,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===============================
  // SOFT CIRCLE
  // ===============================
  Widget _softCircle({
    required double size,
    required double opacity,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: kMainGreen.withOpacity(opacity),
        shape: BoxShape.circle,
      ),
    );
  }
}