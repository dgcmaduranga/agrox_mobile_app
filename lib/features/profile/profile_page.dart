import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../services/theme_provider.dart';

// 🔥 ADD
import '../../services/language_provider.dart';
import '../../widgests/translated_text.dart';

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
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('English'),
                onTap: () {
                  changeLang('en');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('සිංහල'),
                onTap: () {
                  changeLang('si');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('தமிழ்'),
                onTap: () {
                  changeLang('ta');
                  Navigator.pop(context);
                },
              ),
            ],
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

            /// PROFILE CARD
            Container(
              padding: const EdgeInsets.symmetric(
                  vertical: 12, horizontal: 12),
              margin: const EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E1E1E)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.green.shade200,
                    child: Text(
                      user?.email?[0].toUpperCase() ?? "U",
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.displayName ?? "User",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                        Text(
                          user?.email ?? "",
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? Colors.grey
                                : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),

                  GestureDetector(
                    onTap: _showEditProfileDialog,
                    child: Icon(Icons.edit,
                        size: 18,
                        color: isDark
                            ? Colors.white
                            : Colors.black),
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
              onTap: _showResetDialog,
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

  void _showEditProfileDialog() {
    final controller = TextEditingController(
        text: user?.displayName ?? "");

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Profile"),
        content: TextField(
          controller: controller,
          decoration:
              const InputDecoration(labelText: "Name"),
        ),
        actions: [
          TextButton(
              onPressed: () =>
                  Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await user!
                  .updateDisplayName(controller.text);
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Reset Password"),
        content:
            Text("Send link to ${user?.email}"),
        actions: [
          TextButton(
              onPressed: () =>
                  Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await FirebaseAuth.instance
                  .sendPasswordResetEmail(
                      email: user!.email!);

              Navigator.pop(context);

              ScaffoldMessenger.of(context)
                  .showSnackBar(
                const SnackBar(
                    content: Text("Reset link sent!")),
              );
            },
            child: const Text("Send"),
          ),
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
}