import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/language_provider.dart';
import '../../widgests/translated_text.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  void _nextPage() {
    if (_currentIndex == 2) {
      Navigator.pushNamed(context, '/login');
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skip() {
    _controller.jumpToPage(2);
  }

  Widget _dot(bool active) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      width: active ? 10 : 6,
      height: active ? 10 : 6,
      decoration: BoxDecoration(
        color: active ? const Color(0xFF2E7D32) : Colors.grey.shade400,
        shape: BoxShape.circle,
      ),
    );
  }

  Color getBg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.black
          : Colors.white;

  Color getText(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.white
          : Colors.black;

  /// 🔥 SCREEN 1 & 2
  Widget _centerPage({
    required bool isSinhala,
    required String subtitleEN,
    required String subtitleSI,
    required String image,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 60),

          Text(
            isSinhala ? "ආයුබෝවන්" : "Welcome to",
            style: TextStyle(
              fontSize: 16,
              color: getText(context).withOpacity(0.6),
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            "AgroX 🌱",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),

          const SizedBox(height: 20),

          Text(
            isSinhala ? subtitleSI : subtitleEN,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: getText(context).withOpacity(0.6),
            ),
          ),

          const SizedBox(height: 30),

          SizedBox(
            height: 320,
            child: Image.asset(image, fit: BoxFit.contain),
          ),
        ],
      ),
    );
  }

  /// 🔥 FINAL SCREEN (FIXED PERFECT)
  Widget _finalPage(bool isSinhala) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start, // 🔥 IMPORTANT
        children: [

          const SizedBox(height: 60), // 🔥 move everything UP

          /// IMAGE
          SizedBox(
            height: 300, // 🔥 slightly reduced for balance
            child: Image.asset(
              'assets/images/welcome.png',
              fit: BoxFit.contain,
            ),
          ),

          const SizedBox(height: 15),

          /// TITLE
          Text(
            isSinhala ? "ආරම්භ කරන්න 🌱" : "Get Started 🌱",
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),

          const SizedBox(height: 8),

          /// SUBTEXT
          Text(
            isSinhala
                ? "ඇතුල් වීමට හෝ ලියාපදිංචි වීමට මෙතන ක්ලික් කරන්න"
                : "Sign up or login to start using AgroX",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: getText(context).withOpacity(0.6),
            ),
          ),

          const SizedBox(height: 25),

          /// SIGN UP
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/signup');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                isSinhala ? "ලියාපදිංචි වන්න" : "Sign Up",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),

          const SizedBox(height: 12),

          /// LOGIN
          SizedBox(
            width: double.infinity,
            height: 55,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF2E7D32)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                isSinhala ? "පිවිසෙන්න" : "Login",
                style: const TextStyle(
                  color: Color(0xFF2E7D32),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSinhala = context.watch<LanguageProvider>().isSinhala;

    return Scaffold(
      backgroundColor: getBg(context),
      body: SafeArea(
        child: Stack(
          children: [

            PageView(
              controller: _controller,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              children: [

                _centerPage(
                  isSinhala: isSinhala,
                  subtitleEN:
                      "Detect diseases, track weather risks, and get smart farming advice with AgroX.",
                  subtitleSI:
                      "රෝග හඳුනාගෙන, කාලගුණ අවදානම් දැනගෙන, කෘෂි උපදෙස් ලබාගන්න.",
                  image: 'assets/images/welcome.png',
                ),

                _centerPage(
                  isSinhala: isSinhala,
                  subtitleEN:
                      "Detect diseases, get solutions, and protect your harvest.",
                  subtitleSI:
                      "රෝග හඳුනාගෙන, විසඳුම් ලබාගෙන, ඔබේ වගාව ආරක්ෂා කරගන්න.",
                  image: 'assets/images/welcome2.png',
                ),

                _finalPage(isSinhala),
              ],
            ),

            /// SKIP
            Positioned(
              top: 10,
              right: 20,
              child: _currentIndex != 2
                  ? TextButton(
                      onPressed: _skip,
                      child: Text(
                        isSinhala ? "ඉවතට" : "Skip",
                        style: TextStyle(color: getText(context)),
                      ),
                    )
                  : const SizedBox(),
            ),

            /// DOTS + NEXT
            Positioned(
              bottom: 30,
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

                  const SizedBox(height: 20),

                  if (_currentIndex != 2)
                    Container(
                      width: 60,
                      height: 60,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2E7D32),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: _nextPage,
                        icon: const Icon(Icons.arrow_forward,
                            color: Colors.white),
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
}