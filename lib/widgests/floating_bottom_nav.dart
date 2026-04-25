import 'dart:ui';

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
    final Color navColor = isDark
        ? const Color(0xFF161B22).withOpacity(0.94)
        : Colors.white.withOpacity(0.94);

    final Color borderColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.white.withOpacity(0.70);

    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: 86,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Positioned(
              left: 16,
              right: 16,
              bottom: 14,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(34),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    height: 66,
                    decoration: BoxDecoration(
                      color: navColor,
                      borderRadius: BorderRadius.circular(34),
                      border: Border.all(
                        color: borderColor,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(
                            isDark ? 0.42 : 0.10,
                          ),
                          blurRadius: 24,
                          spreadRadius: 1,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _navItem(
                          icon: Icons.home_rounded,
                          label: "Home",
                          index: 0,
                        ),
                        if (showCenterButton) const SizedBox(width: 70),
                        _navItem(
                          icon: Icons.person_rounded,
                          label: "Profile",
                          index: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            if (showCenterButton)
              Positioned(
                top: 0,
                child: GestureDetector(
                  onTap: onCenterTap,
                  child: Container(
                    height: 64,
                    width: 64,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? const Color(0xFF0B0F14)
                          : const Color(0xFFF6F7F9),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(
                            isDark ? 0.42 : 0.14,
                          ),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF2EEA6B),
                            Color(0xFF16A34A),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF22C55E).withOpacity(0.45),
                            blurRadius: 22,
                            spreadRadius: 1,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 27,
                      ),
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

    final Color activeColor = const Color(0xFF22C55E);
    final Color inactiveColor = isDark ? Colors.white60 : Colors.black45;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        width: 96,
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: active
              ? activeColor.withOpacity(isDark ? 0.16 : 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: active
              ? Border.all(
                  color: activeColor.withOpacity(0.22),
                  width: 1,
                )
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: active ? 1.08 : 1.0,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              child: Icon(
                icon,
                size: 22,
                color: active ? activeColor : inactiveColor,
              ),
            ),
            const SizedBox(height: 2),
            Flexible(
              child: TranslatedText(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  height: 1,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  color: active ? activeColor : inactiveColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}