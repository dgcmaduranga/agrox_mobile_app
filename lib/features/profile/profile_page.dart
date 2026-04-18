import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../services/theme_provider.dart';

// 🔥 ADD
import '../../services/language_provider.dart';
import '../../widgests/translated_text.dart';
import 'change_password_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _notifications = true;
  final user = FirebaseAuth.instance.currentUser;

  // 🔥 LANGUAGE CHANGE (use provider, no restart)
  void changeLang(String lang) {
    final provider =
        Provider.of<LanguageProvider>(context, listen: false);
    provider.setLanguage(lang);
  }

  void _showLanguageBottomSheet() {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDark;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 4,
                  width: 48,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                _languageTile('English', 'en'),
                _languageTile('සිංහල', 'si'),
                _languageTile('தமிழ்', 'ta'),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF6F7F9),

      appBar: AppBar(
        backgroundColor:
            isDark ? const Color(0xFF121212) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const TranslatedText(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// PROFILE CARD (modern compact)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          offset: const Offset(0, 2),
                          blurRadius: 6,
                        )
                      ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.green.shade200,
                    child: Text(user?.email?[0].toUpperCase() ?? "U",
                        style: const TextStyle(fontSize: 14)),
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.displayName ?? "User",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : Colors.black,
                            )),
                        const SizedBox(height: 2),
                        Text(user?.email ?? "",
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey : Colors.black54,
                            )),
                      ],
                    ),
                  ),

                  IconButton(
                    onPressed: _showEditProfileDialog,
                    icon: Icon(Icons.edit,
                        size: 18, color: isDark ? Colors.white : Colors.black),
                  )
                ],
              ),
            ),

            const SizedBox(height: 10),

            _sectionTitle("Account", isDark),

            _tile(
              icon: Icons.person,
              titleWidget: const TranslatedText('Edit Profile', style: TextStyle(fontSize:14,fontWeight: FontWeight.w500)),
              subtitleWidget: const TranslatedText('Update your details', style: TextStyle(fontSize:11)),
              isDark: isDark,
              onTap: _showEditProfileDialog,
            ),

            _tile(
              icon: Icons.lock,
              titleWidget: const TranslatedText('Change Password', style: TextStyle(fontSize:14,fontWeight: FontWeight.w500)),
              subtitle: user?.email ?? "",
              isDark: isDark,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordPage()));
              },
            ),

            const SizedBox(height: 6),

            _sectionTitle("Settings", isDark),

            _switchTile(
              icon: Icons.dark_mode,
              title: "Dark Mode",
              value: isDark,
              isDark: isDark,
              onChanged: (v) {
                themeProvider.toggleTheme(v);
              },
            ),

            _switchTile(
              icon: Icons.notifications,
              title: "Notifications",
              value: _notifications,
              isDark: isDark,
              onChanged: (v) {
                setState(() => _notifications = v);
              },
            ),

            // =========================
            // 🌐 LANGUAGE SECTION
            // =========================
            const SizedBox(height: 6),
            _sectionTitle("Language", isDark),

            _tile(
              icon: Icons.language,
              title: "Select Language",
              subtitle: Provider.of<LanguageProvider>(context).language,
              isDark: isDark,
              onTap: _showLanguageBottomSheet,
            ),

            const SizedBox(height: 4),

            _sectionTitle("About", isDark),

            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(
                  vertical: 12, horizontal: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E1E1E)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info,
                      color: Colors.green, size: 18),
                  const SizedBox(width: 10),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                            TranslatedText('AgroX', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black)),
                            TranslatedText('Version 1.0.0', style: TextStyle(fontSize: 11, color: isDark ? Colors.grey : Colors.black54)),
                            TranslatedText('AI-powered agriculture assistant', style: TextStyle(fontSize: 11, color: isDark ? Colors.grey : Colors.black54)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            /// LOGOUT
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(
                      vertical: 14),
                ),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushReplacementNamed(
                      context, '/login');
                },
                child: const TranslatedText('Logout', style: TextStyle(color: Colors.white, fontSize: 14)),
              ),
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),

      bottomNavigationBar: BottomAppBar(
        color:
            isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 8,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceAround,
            children: [
                _navItem(Icons.home, 'Home', 0),
                _navItem(Icons.person, 'Profile', 1),
              ],
          ),
        ),
      ),
    );
  }

  

  ////////////////////////////////////////////////////////////

  Widget _navItem(IconData icon, String label, int index) {
    final isSelected = index == 1;

    return GestureDetector(
      onTap: () {
        if (index == 0) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      },
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Icon(icon,
              color: isSelected
                  ? Colors.green
                  : Colors.grey),
          const SizedBox(height: 2),
            TranslatedText(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? Colors.green : Colors.grey),
            ),
        ],
      ),
    );
  }

  ////////////////////////////////////////////////////////////

  // Generic styled dialog with backdrop blur
  Future<T?> _showStyledDialog<T>({required Widget child}) {
    return showDialog<T>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final isDark = Provider.of<ThemeProvider>(context, listen: false).isDark;

        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Dialog(
            backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
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
          Text('Edit Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black)),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
            decoration: InputDecoration(
              labelText: 'Name',
              labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              isDense: true,
            ),
          ),
          const SizedBox(height: 14),
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
                    Navigator.pop(context);
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
                  } catch (e) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },
                child: const Text('Save'),
              ),
            ],
          )
        ],
      ),
    );
  }

  ////////////////////////////////////////////////////////////

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
        margin:
            const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(
            vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1E1E1E)
              : Colors.white,
          borderRadius:
              BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 18, color: Colors.green),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  titleWidget ?? Text(title ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                        FontWeight.w500,
                      color: isDark
                        ? Colors.white
                        : Colors.black)),
                  subtitleWidget ?? Text(subtitle ?? '',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                        ? Colors.grey
                        : Colors.black54)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 12),
          ],
        ),
      ),
    );
  }

  Widget _switchTile({
    required IconData icon,
    required String title,
    required bool value,
    required bool isDark,
    required Function(bool) onChanged,
  }) {
    return Container(
      margin:
          const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(
          vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E1E1E)
            : Colors.white,
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon,
              size: 18, color: Colors.green),
          const SizedBox(width: 10),
          Expanded(
              child: Text(title,
                  style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? Colors.white
                          : Colors.black))),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TranslatedText(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.grey : Colors.black54,
        ),
      ),
    );
  }

  Widget _languageTile(String label, String code) {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDark;
    return ListTile(
      title: Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black)),
      onTap: () {
        changeLang(code);
        Navigator.pop(context);
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      trailing: Provider.of<LanguageProvider>(context).language == code
          ? const Icon(Icons.check, color: Colors.green)
          : null,
      tileColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
    );
  }
}