import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _pageController = PageController();

  int _currentIndex = 0;
  int _bottomIndex = 0;
  bool _forward = true;

  int _selectedIndex = -1;
  bool _isFabPressed = false;

  final List<String> images = [
    "assets/images/paddy.png",
    "assets/images/tea.png",
    "assets/images/coconut.png",
  ];

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning";
    if (hour < 17) return "Good Afternoon";
    return "Good Evening";
  }

  @override
  void initState() {
    super.initState();

    Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) return;

      setState(() {
        if (_forward) {
          if (_currentIndex < images.length - 1) {
            _currentIndex++;
          } else {
            _forward = false;
            _currentIndex--;
          }
        } else {
          if (_currentIndex > 0) {
            _currentIndex--;
          } else {
            _forward = true;
            _currentIndex++;
          }
        }
      });

      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF6F7F9),

      /// 🔥 FAB
      floatingActionButton: GestureDetector(
        onTapDown: (_) => setState(() => _isFabPressed = true),
        onTapUp: (_) {
          setState(() => _isFabPressed = false);
          Navigator.pushNamed(context, '/scan');
        },
        onTapCancel: () => setState(() => _isFabPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 62,
          width: 62,
          transform: _isFabPressed
              ? (Matrix4.identity()..scale(0.9))
              : Matrix4.identity(),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: _isFabPressed
                  ? Colors.green.shade800
                  : Colors.green.shade300,
              width: _isFabPressed ? 3 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Icon(
            Icons.camera_alt,
            size: 26,
            color: _isFabPressed
                ? Colors.green.shade900
                : Colors.green.shade700,
          ),
        ),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      /// 🔥 SAFE AREA FIX
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 90), // 🔥 IMPORTANT (bottom space)
          physics: const BouncingScrollPhysics(),
          children: [

            /// HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${getGreeting()}, ${user?.displayName ?? "User"} 👋",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                Stack(
                  children: [
                    IconButton(
                      icon: Icon(Icons.notifications_none,
                          color: isDark ? Colors.white : Colors.black),
                      onPressed: () {},
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        height: 8,
                        width: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  ],
                )
              ],
            ),

            const SizedBox(height: 20),

            /// WEATHER
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _WeatherItem(icon: Icons.thermostat, text: "28°C"),
                  _WeatherItem(icon: Icons.water_drop, text: "76%"),
                  _WeatherItem(icon: Icons.grain, text: "1.2 mm"),
                ],
              ),
            ),

            const SizedBox(height: 14),

            /// ALERT
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.orange.shade100,
                    Colors.yellow.shade100,
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  SizedBox(width: 10),
                  Expanded(child: Text("High Risk for Brown Spot")),
                ],
              ),
            ),

            const SizedBox(height: 18),

            /// CAROUSEL
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 170,
                child: Stack(
                  children: [
                    PageView.builder(
                      controller: _pageController,
                      itemCount: images.length,
                      itemBuilder: (context, index) {
                        return Image.asset(
                          images[index],
                          fit: BoxFit.cover,
                        );
                      },
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.5),
                            Colors.transparent
                          ],
                        ),
                      ),
                    ),
                    const Positioned(
                      left: 16,
                      bottom: 16,
                      child: Text(
                        "AI-powered detection\nfor Paddy, Tea & Coconut",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            /// DOTS
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(images.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentIndex == index ? 10 : 6,
                  height: _currentIndex == index ? 10 : 6,
                  decoration: BoxDecoration(
                    color: _currentIndex == index
                        ? Colors.green
                        : Colors.grey.shade400,
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),

            const SizedBox(height: 22),

            _menuCard(0, Icons.camera_alt, Colors.green,
                "Scan Leaf", "Upload or Capture image", () {
              Navigator.pushNamed(context, '/scan');
            }),

            _menuCard(1, Icons.menu_book, Colors.orange,
                "Knowledge Hub", "Learn diseases & treatments", () {
              Navigator.pushNamed(context, '/knowledge');
            }),

            _menuCard(2, Icons.smart_toy, Colors.blue,
                "Ask AgroX AI", "Instant farming advice", () {
              Navigator.pushNamed(context, '/chatbot');
            }),
          ],
        ),
      ),

      /// BOTTOM NAV
      bottomNavigationBar: BottomAppBar(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 8,
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.home, "Home", 0),
              const SizedBox(width: 40),
              _navItem(Icons.person, "Profile", 1),
            ],
          ),
        ),
      ),
    );
  }

  ////////////////////////////////////////////////////////////

  Widget _navItem(IconData icon, String label, int index) {
    final isSelected = _bottomIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        setState(() => _bottomIndex = index);

        if (index == 1) {
          Navigator.pushNamed(context, '/profile');
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon,
              color: isSelected
                  ? Colors.green
                  : Colors.grey),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.green : Colors.grey)),
        ],
      ),
    );
  }

  Widget _menuCard(int index, IconData icon, Color color, String title,
      String subtitle, VoidCallback onTap) {
    final isSelected = _selectedIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedIndex = index);
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 14),
        height: 80,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        transform: isSelected
            ? (Matrix4.identity()..scale(1.02))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.green.shade700
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        ),
        child: Row(
          children: [
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeatherItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _WeatherItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Icon(icon, color: Colors.grey, size: 18),
        const SizedBox(width: 5),
        Text(text,
            style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white : Colors.black)),
      ],
    );
  }
}
