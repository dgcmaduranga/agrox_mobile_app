import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

// ===============================
// APP THEME COLORS
// ===============================
const Color kDarkGreen = Color(0xFF0B5D1E);
const Color kMainGreen = Color(0xFF1B7F35);
const Color kLightGreen = Color(0xFFEAF8E7);

class _SignupPageState extends State<SignupPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  final GoogleSignIn _googleSignIn = GoogleSignIn();

  final FocusNode _nameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmFocus = FocusNode();

  // =========================
  // EMAIL SIGNUP
  // =========================
  Future<void> _signup() async {
    if (_isLoading) return;

    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirm = confirmController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirm.isEmpty) {
      _showError("All fields are required");
      return;
    }

    if (!email.contains('@')) {
      _showError("Enter valid email");
      return;
    }

    if (password.length < 6) {
      _showError("Password must be at least 6 characters");
      return;
    }

    if (password != confirm) {
      _showError("Passwords do not match");
      return;
    }

    try {
      setState(() => _isLoading = true);

      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await userCredential.user?.updateDisplayName(name);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Account created! Please login"),
          backgroundColor: kMainGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      Navigator.pushReplacementNamed(context, '/login');
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? "Signup failed");
    } catch (e) {
      _showError("Something went wrong");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // =========================
  // GOOGLE SIGNUP
  // =========================
  Future<void> _googleSignup() async {
    if (_isLoading) return;

    try {
      setState(() => _isLoading = true);

      await _googleSignIn.signOut();

      final googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      if (!mounted) return;

      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? "Google signup failed");
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

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();

    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();

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
              Icons.person_add_alt_1_rounded,
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
                  "Register Account",
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
                  "Start your AgroX journey 🌱",
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

                        const SizedBox(height: 28),

                        const Center(
                          child: Text(
                            "Create Your AgroX Account",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF102014),
                              letterSpacing: -0.2,
                              height: 1.15,
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        Center(
                          child: Text(
                            "Start your smart farming journey today",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black.withOpacity(0.55),
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

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
                              _field(
                                controller: nameController,
                                focusNode: _nameFocus,
                                label: "Name",
                                hint: "Enter Your Name",
                                icon: Icons.person_outline_rounded,
                              ),

                              const SizedBox(height: 12),

                              _field(
                                controller: emailController,
                                focusNode: _emailFocus,
                                label: "Email",
                                hint: "Enter Your Email",
                                icon: Icons.email_outlined,
                              ),

                              const SizedBox(height: 12),

                              _field(
                                controller: passwordController,
                                focusNode: _passwordFocus,
                                label: "Password",
                                hint: "Enter Your Password",
                                icon: Icons.lock_outline_rounded,
                                isPassword: true,
                              ),

                              const SizedBox(height: 12),

                              _field(
                                controller: confirmController,
                                focusNode: _confirmFocus,
                                label: "Confirm Password",
                                hint: "Re-enter Password",
                                icon: Icons.verified_user_outlined,
                                isPassword: true,
                                isConfirm: true,
                              ),

                              const SizedBox(height: 18),

                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _signup,
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

                              const SizedBox(height: 19),

                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: Colors.black.withOpacity(0.10),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    child: Text(
                                      "OR",
                                      style: TextStyle(
                                        color: Colors.black.withOpacity(0.45),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: Colors.black.withOpacity(0.10),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 19),

                              SizedBox(
                                width: double.infinity,
                                height: 55,
                                child: OutlinedButton.icon(
                                  onPressed: _isLoading ? null : _googleSignup,
                                  icon: Image.network(
                                    'https://img.icons8.com/color/48/google-logo.png',
                                    height: 22,
                                  ),
                                  label: const Text(
                                    "Continue with Google",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF102014),
                                    backgroundColor: Colors.white,
                                    side: BorderSide(
                                      color: kDarkGreen.withOpacity(0.12),
                                      width: 1.2,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 22),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Already have an account? ",
                              style: TextStyle(
                                color: Colors.black.withOpacity(0.58),
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: const Text(
                                "Login",
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
  // FIELD
  // ===============================
  Widget _field({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool isConfirm = false,
  }) {
    final bool visible = isConfirm ? !_obscureConfirm : !_obscurePassword;

    return TextField(
      controller: controller,
      focusNode: focusNode,
      obscureText: isPassword ? !visible : false,
      style: const TextStyle(
        color: Color(0xFF102014),
        fontSize: 14.5,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
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
          child: Icon(
            icon,
            size: 21,
            color: kDarkGreen,
          ),
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  visible
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  color: Colors.black45,
                  size: 21,
                ),
                onPressed: () {
                  setState(() {
                    if (isConfirm) {
                      _obscureConfirm = !_obscureConfirm;
                    } else {
                      _obscurePassword = !_obscurePassword;
                    }
                  });
                },
              )
            : null,
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