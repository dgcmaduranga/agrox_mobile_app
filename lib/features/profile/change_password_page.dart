import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../services/theme_provider.dart';
import '../../services/language_provider.dart';
import '../../widgests/translated_text.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

// ===============================
// APP THEME COLORS
// ===============================
const Color kDarkGreen = Color(0xFF0B5D1E);
const Color kMainGreen = Color(0xFF1B7F35);
const Color kLightGreen = Color(0xFFEAF7EE);

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();

  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _loading = false;
  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final current = _currentCtrl.text.trim();
    final newPassword = _newCtrl.text.trim();

    setState(() => _loading = true);

    try {
      final curUser = FirebaseAuth.instance.currentUser;

      if (curUser == null || curUser.email == null) {
        throw 'User not available';
      }

      final cred = EmailAuthProvider.credential(
        email: curUser.email!,
        password: current,
      );

      await curUser.reauthenticateWithCredential(cred);
      await curUser.updatePassword(newPassword);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Password updated successfully'),
          backgroundColor: kMainGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message = e.message ?? 'Authentication error';

      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        message = 'Current password is incorrect';
      } else if (e.code == 'weak-password') {
        message = 'New password is too weak';
      } else if (e.code == 'requires-recent-login') {
        message = 'Please login again and try changing your password';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ===============================
  // TOP GREEN HEADER
  // ===============================
  Widget _premiumTopHeader(BuildContext context) {
    return Container(
      width: double.infinity,
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
            onPressed: () => Navigator.pop(context),
          ),

          Container(
            width: 48,
            height: 48,
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
            child: const Icon(
              Icons.lock_reset_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),

          const SizedBox(width: 12),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TranslatedText(
                  "Change Password",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: 4),
                TranslatedText(
                  "Secure your AgroX account 🔐",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          Container(
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
              Icons.shield_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDark;

    Provider.of<LanguageProvider>(context);

    final bgColor = isDark ? const Color(0xFF0B0F14) : const Color(0xFFF6F8F5);
    final cardColor = isDark ? const Color(0xFF161B22) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF102014);
    final subTextColor = isDark ? Colors.white60 : Colors.black54;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              child: _premiumTopHeader(context),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ===============================
                    // FORM CARD
                    // ===============================
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.06)
                              : kDarkGreen.withOpacity(0.06),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(
                              isDark ? 0.18 : 0.045,
                            ),
                            blurRadius: 16,
                            offset: const Offset(0, 7),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _passwordField(
                              controller: _currentCtrl,
                              label: 'Current Password',
                              hint: 'Enter current password',
                              icon: Icons.lock_outline_rounded,
                              visible: _showCurrent,
                              onToggle: () {
                                setState(() => _showCurrent = !_showCurrent);
                              },
                              isDark: isDark,
                            ),

                            const SizedBox(height: 14),

                            _passwordField(
                              controller: _newCtrl,
                              label: 'New Password',
                              hint: 'Enter new password',
                              icon: Icons.password_rounded,
                              visible: _showNew,
                              onToggle: () {
                                setState(() => _showNew = !_showNew);
                              },
                              isDark: isDark,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Enter new password';
                                }

                                if (v.trim().length < 6) {
                                  return 'Password must be at least 6 characters';
                                }

                                if (v.trim() == _currentCtrl.text.trim()) {
                                  return 'New password must be different';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 14),

                            _passwordField(
                              controller: _confirmCtrl,
                              label: 'Confirm New Password',
                              hint: 'Re-enter new password',
                              icon: Icons.verified_user_outlined,
                              visible: _showConfirm,
                              onToggle: () {
                                setState(() => _showConfirm = !_showConfirm);
                              },
                              isDark: isDark,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Confirm your new password';
                                }

                                if (v.trim() != _newCtrl.text.trim()) {
                                  return 'Passwords do not match';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 18),

                            // ===============================
                            // PASSWORD TIPS CARD
                            // ===============================
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(13),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? kDarkGreen.withOpacity(0.14)
                                    : kLightGreen.withOpacity(0.85),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: kDarkGreen.withOpacity(0.08),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.shield_rounded,
                                    color: kDarkGreen,
                                    size: 21,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TranslatedText(
                                      'Use at least 6 characters. Avoid using your old password or simple words.',
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white70
                                            : kDarkGreen,
                                        fontSize: 12.5,
                                        height: 1.35,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // ===============================
                            // UPDATE BUTTON
                            // ===============================
                            SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kDarkGreen,
                                  foregroundColor: Colors.white,
                                  elevation: 8,
                                  shadowColor: kDarkGreen.withOpacity(0.32),
                                  disabledBackgroundColor:
                                      kDarkGreen.withOpacity(0.55),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                onPressed: _loading ? null : _updatePassword,
                                child: _loading
                                    ? const SizedBox(
                                        height: 21,
                                        width: 21,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.4,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const TranslatedText(
                                        'Update Password',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 15.5,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ===============================
                    // SECURITY NOTE
                    // ===============================
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.06)
                              : kDarkGreen.withOpacity(0.06),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(
                              isDark ? 0.16 : 0.04,
                            ),
                            blurRadius: 13,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? kDarkGreen.withOpacity(0.18)
                                  : kLightGreen,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Icon(
                              Icons.privacy_tip_rounded,
                              color: kDarkGreen,
                              size: 23,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TranslatedText(
                              'For security, you must enter your current password before setting a new one.',
                              style: TextStyle(
                                color: subTextColor,
                                fontSize: 12.7,
                                height: 1.35,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ===============================
                    // EXTRA SECURITY CARD
                    // ===============================
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.06)
                              : kDarkGreen.withOpacity(0.06),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(
                              isDark ? 0.16 : 0.04,
                            ),
                            blurRadius: 13,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.blue.withOpacity(0.12)
                                  : Colors.blue.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Icon(
                              Icons.verified_user_rounded,
                              color: isDark
                                  ? Colors.blue.shade200
                                  : Colors.blue.shade700,
                              size: 23,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'After updating your password, use the new password for your next login.',
                              style: TextStyle(
                                color: subTextColor,
                                fontSize: 12.7,
                                height: 1.35,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
  // PREMIUM PASSWORD FIELD
  // ===============================
  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool visible,
    required VoidCallback onToggle,
    required bool isDark,
    String? Function(String?)? validator,
  }) {
    final fieldBg = isDark ? const Color(0xFF0F1720) : const Color(0xFFF8FAF8);
    final textColor = isDark ? Colors.white : const Color(0xFF102014);

    return TextFormField(
      controller: controller,
      obscureText: !visible,
      style: TextStyle(
        color: textColor,
        fontSize: 14.5,
        fontWeight: FontWeight.w600,
      ),
      validator: validator ??
          (v) {
            if (v == null || v.trim().isEmpty) {
              return 'This field is required';
            }
            return null;
          },
      decoration: InputDecoration(
        label: TranslatedText(
          label,
          style: TextStyle(
            color: isDark ? Colors.white60 : Colors.black54,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        hintText: hint,
        hintStyle: TextStyle(
          color: isDark ? Colors.white30 : Colors.black38,
          fontSize: 13,
        ),
        prefixIcon: Container(
          margin: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: isDark ? kDarkGreen.withOpacity(0.18) : kLightGreen,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: kDarkGreen,
            size: 21,
          ),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            visible
                ? Icons.visibility_off_rounded
                : Icons.visibility_rounded,
            color: isDark ? Colors.white54 : Colors.black45,
            size: 21,
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: fieldBg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : kDarkGreen.withOpacity(0.08),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: kMainGreen,
            width: 1.4,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 1.2,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 1.4,
          ),
        ),
      ),
    );
  }
}