import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _floatAnimation;

  // =========================
  // APP COLORS
  // =========================
  static const Color kDarkGreen = Color(0xFF0B5D1E);
  static const Color kMainGreen = Color(0xFF1B7F35);
  static const Color kSoftGreen = Color(0xFFEAF8E7);

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0.0,
          0.85,
          curve: Curves.easeInOut,
        ),
      ),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.82,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _floatAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _controller.forward();
    _startTimer();
  }

  // =========================
  // AUTH CHECK + NAVIGATION
  // =========================
  void _startTimer() {
    Timer(const Duration(seconds: 3), () async {
      if (!mounted) return;

      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        Navigator.pushReplacementNamed(context, '/welcome');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // =========================
  // UI
  // =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // =========================
          // CLEAN WHITE BACKGROUND
          // =========================
          Positioned.fill(
            child: Container(
              color: Colors.white,
            ),
          ),

          // =========================
          // SOFT PREMIUM BACKGROUND SHAPES
          // =========================
          AnimatedBuilder(
            animation: _floatAnimation,
            builder: (context, child) {
              return Stack(
                children: [
                  Positioned(
                    top: -70 + (_floatAnimation.value * 12),
                    right: -75,
                    child: _softCircle(
                      size: 190,
                      opacity: 0.045,
                    ),
                  ),
                  Positioned(
                    bottom: 85 - (_floatAnimation.value * 12),
                    left: -95,
                    child: _softCircle(
                      size: 230,
                      opacity: 0.050,
                    ),
                  ),
                  Positioned(
                    top: 170 + (_floatAnimation.value * 8),
                    left: 34,
                    child: _iconBubble(
                      icon: Icons.eco_rounded,
                      size: 44,
                      opacity: 0.060,
                    ),
                  ),
                  Positioned(
                    bottom: 185 - (_floatAnimation.value * 8),
                    right: 42,
                    child: _iconBubble(
                      icon: Icons.grass_rounded,
                      size: 52,
                      opacity: 0.060,
                    ),
                  ),
                ],
              );
            },
          ),

          // =========================
          // MAIN CONTENT
          // =========================
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 3),

                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Column(
                        children: [
                          // =========================
                          // BIG CLEAN LOGO ONLY
                          // No extra AgroX name below
                          // =========================
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 10,
                            ),
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: 285,
                              fit: BoxFit.contain,
                            ),
                          ),

                          const SizedBox(height: 26),

                          // =========================
                          // PROFESSIONAL SUBTITLE ONLY
                          // =========================
                          Text(
                            'Smart Crop Disease Detection',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black.withOpacity(0.58),
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.15,
                            ),
                          ),

                          const SizedBox(height: 18),

                          // =========================
                          // PREMIUM TAG
                          // =========================
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7FBF7),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: kDarkGreen.withOpacity(0.07),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.035),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.eco_rounded,
                                  color: kDarkGreen,
                                  size: 17,
                                ),
                                SizedBox(width: 7),
                                Text(
                                  'AI-powered agriculture assistant',
                                  style: TextStyle(
                                    color: kDarkGreen,
                                    fontSize: 12.8,
                                    fontWeight: FontWeight.w800,
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

                const Spacer(flex: 2),

                // =========================
                // PREMIUM LOADING CARD
                // =========================
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(28, 0, 28, 40),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FCF9),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: kDarkGreen.withOpacity(0.06),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.035),
                          blurRadius: 16,
                          offset: const Offset(0, 7),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: kDarkGreen,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Preparing your dashboard...',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.black.withOpacity(0.58),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // SOFT CIRCLE
  // =========================
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

  // =========================
  // SMALL ICON BUBBLE
  // =========================
  Widget _iconBubble({
    required IconData icon,
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
      child: Icon(
        icon,
        color: kDarkGreen.withOpacity(0.45),
        size: size * 0.48,
      ),
    );
  }
}