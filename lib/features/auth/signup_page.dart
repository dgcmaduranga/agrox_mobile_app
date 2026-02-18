import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// =========================
  /// EMAIL SIGNUP
  /// =========================
  Future<void> _signup() async {
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

      /// set display name
      await userCredential.user?.updateDisplayName(name);

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }

    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? "Signup failed");
    } catch (e) {
      _showError("Something went wrong");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// =========================
  /// GOOGLE SIGNUP
  /// =========================
  Future<void> _googleSignup() async {
    try {
      setState(() => _isLoading = true);

      /// 🔥 show account picker always
      await _googleSignIn.signOut();

      final googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }

    } catch (e) {
      _showError("Google signup failed");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// =========================
  /// ERROR
  /// =========================
  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// =========================
  /// DISPOSE
  /// =========================
  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  /// =========================
  /// UI
  /// =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,

      body: SafeArea(
        child: Stack(
          children: [

            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [

                      /// BACK
                      Align(
                        alignment: Alignment.topLeft,
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back),
                        ),
                      ),

                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [

                            const Text(
                              "Create Account",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 8),

                            const Text(
                              "Sign up to get started",
                              style: TextStyle(color: Colors.black54),
                            ),

                            const SizedBox(height: 30),

                            /// NAME
                            TextField(
                              controller: nameController,
                              decoration: _input(
                                  "Name", Icons.person_outline),
                            ),

                            const SizedBox(height: 16),

                            /// EMAIL
                            TextField(
                              controller: emailController,
                              keyboardType:
                                  TextInputType.emailAddress,
                              decoration: _input(
                                  "Email", Icons.email_outlined),
                            ),

                            const SizedBox(height: 16),

                            /// PASSWORD
                            TextField(
                              controller: passwordController,
                              obscureText: _obscurePassword,
                              decoration: _input(
                                "Password",
                                Icons.lock_outline,
                                isPassword: true,
                                obscure: _obscurePassword,
                                toggle: () {
                                  setState(() {
                                    _obscurePassword =
                                        !_obscurePassword;
                                  });
                                },
                              ),
                            ),

                            const SizedBox(height: 16),

                            /// CONFIRM PASSWORD
                            TextField(
                              controller: confirmController,
                              obscureText: _obscureConfirm,
                              decoration: _input(
                                "Confirm Password",
                                Icons.lock_outline,
                                isPassword: true,
                                obscure: _obscureConfirm,
                                toggle: () {
                                  setState(() {
                                    _obscureConfirm =
                                        !_obscureConfirm;
                                  });
                                },
                              ),
                            ),

                            const SizedBox(height: 24),

                            /// SIGNUP BUTTON
                            SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: ElevatedButton(
                                onPressed: _signup,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color(0xFF2E7D32),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(30),
                                  ),
                                ),
                                child: const Text("Sign Up"),
                              ),
                            ),

                            const SizedBox(height: 20),

                            /// OR
                            Row(
                              children: const [
                                Expanded(child: Divider()),
                                Padding(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 8),
                                  child: Text("OR"),
                                ),
                                Expanded(child: Divider()),
                              ],
                            ),

                            const SizedBox(height: 20),

                            /// GOOGLE
                            SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: OutlinedButton.icon(
                                onPressed: _googleSignup,
                                icon: Image.network(
                                  'https://img.icons8.com/color/48/google-logo.png',
                                  height: 22,
                                ),
                                label: const Text(
                                  "Sign up with Google",
                                ),
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(30),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 30),

                            /// LOGIN LINK
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                const Text(
                                    "Already have an account? "),
                                GestureDetector(
                                  onTap: () =>
                                      Navigator.pop(context),
                                  child: const Text(
                                    "Login",
                                    style: TextStyle(
                                      color: Color(0xFF2E7D32),
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            /// LOADING
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// INPUT STYLE
  InputDecoration _input(
    String hint,
    IconData icon, {
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? toggle,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      suffixIcon: isPassword
          ? IconButton(
              icon: Icon(
                obscure
                    ? Icons.visibility_off
                    : Icons.visibility,
              ),
              onPressed: toggle,
            )
          : null,
      filled: true,
      fillColor: Colors.grey.shade100,
      contentPadding:
          const EdgeInsets.symmetric(vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}
