import 'package:flutter/material.dart';
import 'translated_text.dart';

class FloatingBottomNav extends StatelessWidget {
  final int activeIndex;
  final bool isDark;
  final ValueChanged<int> onTap;
  final VoidCallback? onCenterTap;
  final bool showCenterButton;

  const FloatingBottomNav({
    required this.activeIndex,
    required this.isDark,
    required this.onTap,
    this.onCenterTap,
    this.showCenterButton = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final navColor = isDark
      ? const Color(0xFF1C1C1E)
      : Colors.white;

    return SafeArea(
      bottom: false, // 🔥 VERY IMPORTANT (fix gap issue)
      child: SizedBox(
        height: 65, // compact overall height
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [

            // 🔹 NAV BAR
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 58, // compact nav
              decoration: BoxDecoration(
                color: navColor,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.5 : 0.08),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _navItem(
                    icon: Icons.home,
                    label: "Home",
                    index: 0,
                  ),

                  if (showCenterButton) const SizedBox(width: 50),

                  _navItem(
                    icon: Icons.person,
                    label: "Profile",
                    index: 1,
                  ),
                ],
              ),
            ),

            // 🔥 CENTER BUTTON (ONLY IF ENABLED)
            if (showCenterButton)
              Positioned(
                top: -16, // 🔥 FLOAT PROPERLY (not too high)
                child: GestureDetector(
                  onTap: onCenterTap,
                  child: Container(
                    height: 54,
                    width: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        // glow
                        BoxShadow(
                          color: const Color(0xFF22C55E).withOpacity(0.35),
                          blurRadius: 14,
                        ),
                        // depth
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final bool active = index == activeIndex;

    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFF22C55E).withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: active
                  ? const Color(0xFF22C55E)
                  : (isDark ? Colors.white70 : Colors.grey),
            ),
            const SizedBox(height: 3),
            TranslatedText(
              label,
              style: TextStyle(
                fontSize: 11,
                color: active
                    ? const Color(0xFF22C55E)
                    : (isDark ? Colors.white70 : Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}