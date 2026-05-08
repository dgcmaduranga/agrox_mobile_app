import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

// ===============================
// APP THEME COLORS
// ===============================
const Color kDarkGreen = Color(0xFF0B5D1E);
const Color kMainGreen = Color(0xFF1B7F35);
const Color kLightGreen = Color(0xFFEAF8E7);

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _emailController = TextEditingController();
  final FocusNode _emailFocus = FocusNode();

  bool _isLoading = false;

  // =========================
  // SEND RESET EMAIL
  // =========================
  Future<void> _sendResetEmail() async {
    if (_isLoading) return;

    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showError("Enter your email");
      return;
    }

    if (!email.contains('@')) {
      _showError("Enter valid email");
      return;
    }

    try {
      setState(() => _isLoading = true);

      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return;

      _showSuccessDialog();
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? "Failed to send email");
    } catch (e) {
      _showError("Something went wrong");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String msg) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // =========================
  // SUCCESS DIALOG
  // =========================
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
        contentPadding: const EdgeInsets.fromLTRB(22, 14, 22, 10),
        actionsPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
        title: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: kLightGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mark_email_read_rounded,
                color: kDarkGreen,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                "Reset Link Sent",
                style: TextStyle(
                  color: Color(0xFF102014),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          "Password reset link sent.\nPlease check your email inbox.",
          style: TextStyle(
            color: Colors.black54,
            fontSize: 14,
            height: 1.45,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kDarkGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                "OK",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  // ===============================
  // TOP GREEN HEADER
  // ===============================
  Widget _premiumTopHeader() {
    return Container(
      width: double.infinity,
      height: 86,
      padding: const EdgeInsets.fromLTRB(8, 11, 14, 11),
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

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Forgot Password",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Recover your AgroX account 🌱",
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
              Icons.eco_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  // ===============================
  // UI
  // ===============================
  @override
  Widget build(BuildContext context) {
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(color: Colors.white),
            ),

            Positioned(
              top: -80,
              right: -80,
              child: _softCircle(size: 210, opacity: 0.055),
            ),

            Positioned(
              bottom: 40,
              left: -105,
              child: _softCircle(size: 240, opacity: 0.050),
            ),

            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: isKeyboardOpen
                      ? const BouncingScrollPhysics()
                      : const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    18,
                    10,
                    18,
                    MediaQuery.of(context).viewInsets.bottom + 18,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 28,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _premiumTopHeader(),

                        const SizedBox(height: 34),

                        const Center(
                          child: Text(
                            "Reset Password",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 27,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF102014),
                              letterSpacing: -0.2,
                              height: 1.15,
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        Center(
                          child: Text(
                            "Enter your registered email address and we will send you a password reset link.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black.withOpacity(0.55),
                              height: 1.45,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(
                              color: kDarkGreen.withOpacity(0.06),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.045),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _emailField(),

                              const SizedBox(height: 18),

                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(13),
                                decoration: BoxDecoration(
                                  color: kLightGreen.withOpacity(0.85),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: kDarkGreen.withOpacity(0.08),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.info_rounded,
                                      color: kDarkGreen,
                                      size: 21,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        "Use the email address connected to your AgroX account.",
                                        style: TextStyle(
                                          color: kDarkGreen.withOpacity(0.85),
                                          fontSize: 12.5,
                                          height: 1.35,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 22),

                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed:
                                      _isLoading ? null : _sendResetEmail,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: kDarkGreen,
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor:
                                        kDarkGreen.withOpacity(0.65),
                                    elevation: 8,
                                    shadowColor: kDarkGreen.withOpacity(0.28),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.4,
                                          ),
                                        )
                                      : const Text(
                                          "Continue",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: TextStyle(
                                color: Colors.black.withOpacity(0.58),
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(context, '/signup');
                              },
                              child: const Text(
                                "Sign Up",
                                style: TextStyle(
                                  color: kDarkGreen,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            if (_isLoading)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: Colors.black.withOpacity(0.10),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ===============================
  // EMAIL FIELD
  // ===============================
  Widget _emailField() {
    return TextField(
      controller: _emailController,
      focusNode: _emailFocus,
      keyboardType: TextInputType.emailAddress,
      style: const TextStyle(
        color: Color(0xFF102014),
        fontSize: 14.5,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: "Email",
        hintText: "Enter Your Email",
        labelStyle: TextStyle(
          color: Colors.black.withOpacity(0.50),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: TextStyle(
          color: Colors.black.withOpacity(0.34),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Container(
          margin: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: kLightGreen,
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(
            Icons.email_outlined,
            size: 21,
            color: kDarkGreen,
          ),
        ),
        filled: true,
        fillColor: const Color(0xFFF7FAF7),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(19),
          borderSide: BorderSide(
            color: kDarkGreen.withOpacity(0.08),
            width: 1.1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(19),
          borderSide: const BorderSide(
            color: kMainGreen,
            width: 1.5,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(19),
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