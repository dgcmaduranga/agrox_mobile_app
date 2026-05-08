import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/theme_provider.dart';
import '../../services/notification_service.dart';
import '../../widgests/translated_text.dart';

import 'change_password_page.dart';
import 'detection_history_page.dart';
import 'saved_treatments_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

// ===============================
// APP THEME COLORS
// ===============================
const Color kDarkGreen = Color(0xFF0B5D1E);
const Color kMainGreen = Color(0xFF1B7F35);
const Color kLightGreen = Color(0xFFEAF7EE);

class _ProfilePageState extends State<ProfilePage> {
  static const String _notificationPrefKey = 'agrox_notifications_enabled';

  bool _notifications = true;
  bool _notificationLoading = true;

  User? get user => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreference();
  }

  // =========================
  // LOAD NOTIFICATION SETTING
  // =========================
  Future<void> _loadNotificationPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedValue = prefs.getBool(_notificationPrefKey);

      if (!mounted) return;

      setState(() {
        _notifications = savedValue ?? true;
        _notificationLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _notifications = true;
        _notificationLoading = false;
      });
    }
  }

  // =========================
  // TOGGLE NOTIFICATIONS
  // =========================
  Future<void> _toggleNotifications(bool value) async {
    if (_notificationLoading) return;

    setState(() {
      _notifications = value;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_notificationPrefKey, value);

      if (value) {
        await NotificationService.instance.init();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notifications turned on'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notifications turned off'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _notifications = !value;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Notification setting error: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // =========================
  // FIXED TOP GREEN HEADER
  // =========================
  Widget _premiumTopHeader(BuildContext context, User? currentUser) {
    final String name =
        currentUser?.displayName?.trim().isNotEmpty == true
            ? currentUser!.displayName!.trim()
            : 'Profile';

    final String email = currentUser?.email ?? '';

    final String initial = email.isNotEmpty
        ? email[0].toUpperCase()
        : name.isNotEmpty
            ? name[0].toUpperCase()
            : 'U';

    return Container(
      width: double.infinity,
      height: 96,
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
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/home');
            },
          ),

          const SizedBox(width: 2),

          Container(
            width: 50,
            height: 50,
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
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TranslatedText(
                  "Profile",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  email.isNotEmpty ? email : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.78),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          GestureDetector(
            onTap: _showEditProfileDialog,
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
                Icons.edit_rounded,
                color: Colors.white,
                size: 21,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDark;
    final currentUser = user;

    final Color bgColor =
        isDark ? const Color(0xFF0B0F14) : const Color(0xFFF6F8F5);

    return Scaffold(
      extendBody: true,
      backgroundColor: bgColor,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // =========================
            // SCROLL CONTENT ONLY
            // =========================
            SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(14, 120, 14, 178),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle("Account", isDark),

                  _tile(
                    icon: Icons.person_rounded,
                    titleWidget: const TranslatedText(
                      'Edit Profile',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitleWidget: const TranslatedText(
                      'Update your details',
                      style: TextStyle(fontSize: 11.8),
                    ),
                    isDark: isDark,
                    onTap: _showEditProfileDialog,
                  ),

                  _tile(
                    icon: Icons.lock_rounded,
                    titleWidget: const TranslatedText(
                      'Change Password',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitle: currentUser?.email ?? "",
                    isDark: isDark,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ChangePasswordPage(),
                        ),
                      );
                    },
                  ),

                  _tile(
                    icon: Icons.history_rounded,
                    titleWidget: const TranslatedText(
                      'Detection History',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitleWidget: const TranslatedText(
                      'View your last 5 detection results',
                      style: TextStyle(fontSize: 11.8),
                    ),
                    isDark: isDark,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DetectionHistoryPage(),
                        ),
                      );
                    },
                  ),

                  _tile(
                    icon: Icons.bookmark_rounded,
                    titleWidget: const TranslatedText(
                      'Saved Treatments',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitleWidget: const TranslatedText(
                      'View your saved treatment tips',
                      style: TextStyle(fontSize: 11.8),
                    ),
                    isDark: isDark,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SavedTreatmentsPage(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  _sectionTitle("Settings", isDark),

                  _switchTile(
                    icon: Icons.dark_mode_rounded,
                    title: "Dark Mode",
                    value: isDark,
                    isDark: isDark,
                    onChanged: (v) {
                      themeProvider.toggleTheme(v);
                    },
                  ),

                  _switchTile(
                    icon: _notifications
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_off_rounded,
                    title: "Notifications",
                    value: _notifications,
                    isDark: isDark,
                    onChanged: _toggleNotifications,
                  ),

                  const SizedBox(height: 12),

                  _sectionTitle("About", isDark),

                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      vertical: 13,
                      horizontal: 14,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF161B22) : Colors.white,
                      borderRadius: BorderRadius.circular(21),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.06)
                            : kDarkGreen.withOpacity(0.06),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              Colors.black.withOpacity(isDark ? 0.18 : 0.035),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color:
                                isDark ? const Color(0xFF102A1A) : kLightGreen,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.info_rounded,
                            color: kDarkGreen,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TranslatedText(
                                'AgroX',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w900,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF102014),
                                ),
                              ),
                              const SizedBox(height: 3),
                              TranslatedText(
                                'Version 1.0.0',
                                style: TextStyle(
                                  fontSize: 11.8,
                                  color:
                                      isDark ? Colors.white60 : Colors.black54,
                                ),
                              ),
                              TranslatedText(
                                'AI-powered agriculture assistant',
                                style: TextStyle(
                                  fontSize: 11.8,
                                  color:
                                      isDark ? Colors.white60 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ===============================
            // FIXED TOP HEADER
            // ===============================
            Positioned(
              left: 14,
              right: 14,
              top: 8,
              child: _premiumTopHeader(context, currentUser),
            ),

            // ===============================
            // FIXED LOGOUT BUTTON + BOTTOM NAV
            // ===============================
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0B0F14).withOpacity(0.94)
                        : const Color(0xFFF6F8F5).withOpacity(0.94),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: _showLogoutConfirmation,
                        child: Container(
                          width: double.infinity,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE53935),
                            borderRadius: BorderRadius.circular(17),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.22),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'Logout',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _ProfileBottomNav(
                        isDark: isDark,
                        activeIndex: 1,
                        onHomeTap: () {
                          Navigator.pushReplacementNamed(context, '/home');
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // STYLED DIALOG
  // =========================
  Future<T?> _showStyledDialog<T>({required Widget child}) {
    return showDialog<T>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final isDark = Provider.of<ThemeProvider>(
          context,
          listen: false,
        ).isDark;

        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Dialog(
            backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: child,
            ),
          ),
        );
      },
    );
  }

  void _showEditProfileDialog() {
    final controller = TextEditingController(text: user?.displayName ?? "");
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDark;

    _showStyledDialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Edit Profile',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF102014),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: controller,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF102014),
            ),
            decoration: InputDecoration(
              labelText: 'Name',
              labelStyle: TextStyle(
                color: isDark ? Colors.white60 : Colors.black54,
              ),
              filled: true,
              fillColor: isDark ? const Color(0xFF0B0F14) : kLightGreen,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: kMainGreen,
                  width: 1.4,
                ),
              ),
              isDense: true,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await user!.updateDisplayName(controller.text.trim());
                    await user!.reload();

                    if (!mounted) return;

                    Navigator.pop(context);
                    setState(() {});

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Profile updated'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;

                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kMainGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================
  // LOGOUT
  // =========================
  Future<void> _showLogoutConfirmation() async {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDark;

    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (ctx) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: AlertDialog(
            backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            title: Text(
              'Confirm Logout',
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF102014),
                fontWeight: FontWeight.w900,
              ),
            ),
            content: Text(
              'Are you sure you want to logout?',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);

                  await FirebaseAuth.instance.signOut();

                  if (!mounted) return;

                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/welcome',
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Logout',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // =========================
  // TILE
  // =========================
  Widget _tile({
    required IconData icon,
    String? title,
    String? subtitle,
    Widget? titleWidget,
    Widget? subtitleWidget,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 13),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161B22) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : kDarkGreen.withOpacity(0.06),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.18 : 0.035),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF102A1A) : kLightGreen,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 21, color: kMainGreen),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  titleWidget ??
                      Text(
                        title ?? '',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color:
                              isDark ? Colors.white : const Color(0xFF102014),
                        ),
                      ),
                  const SizedBox(height: 3),
                  subtitleWidget ??
                      Text(
                        subtitle ?? '',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.8,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                ],
              ),
            ),
            Container(
              width: 29,
              height: 29,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.06) : kLightGreen,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: isDark ? Colors.white60 : kDarkGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // SWITCH TILE
  // =========================
  Widget _switchTile({
    required IconData icon,
    required String title,
    required bool value,
    required bool isDark,
    required Function(bool) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 13),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : kDarkGreen.withOpacity(0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.18 : 0.035),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF102A1A) : kLightGreen,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 21, color: kMainGreen),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: TranslatedText(
              title,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF102014),
              ),
            ),
          ),
          Transform.scale(
            scale: 0.88,
            child: Switch(
              value: value,
              activeColor: kMainGreen,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TranslatedText(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w900,
          color: isDark ? Colors.white60 : Colors.black54,
        ),
      ),
    );
  }
}

// ===============================
// PROFILE BOTTOM NAV - HOME + PROFILE ONLY
// ===============================
class _ProfileBottomNav extends StatelessWidget {
  final bool isDark;
  final int activeIndex;
  final VoidCallback onHomeTap;

  const _ProfileBottomNav({
    required this.isDark,
    required this.activeIndex,
    required this.onHomeTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF161B22).withOpacity(0.96)
            : Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.black12,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _bottomItem(
            icon: Icons.home_rounded,
            label: 'Home',
            selected: activeIndex == 0,
            onTap: onHomeTap,
          ),
          _bottomItem(
            icon: Icons.person_rounded,
            label: 'Profile',
            selected: activeIndex == 1,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _bottomItem({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 112,
        height: 44,
        decoration: BoxDecoration(
          color: selected ? kLightGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22,
              color: selected ? kMainGreen : Colors.grey,
            ),
            const SizedBox(height: 1),
            TranslatedText(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                color: selected ? kMainGreen : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}