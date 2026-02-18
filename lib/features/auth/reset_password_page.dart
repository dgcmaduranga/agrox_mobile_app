import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() =>
      _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {

  final _emailController = TextEditingController();
  final FocusNode _emailFocus = FocusNode();

  bool _isLoading = false;

  Future<void> _sendResetEmail() async {
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

      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: email);

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Success"),
          content: const Text(
              "Password reset link sent.\nCheck your email."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );

    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? "Failed to send email");
    } catch (e) {
      _showError("Something went wrong");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    /// 🔥 keyboard detect
    final isKeyboardOpen =
        MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,

      body: SafeArea(
        child: Stack(
          children: [

            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  /// 🔥 scroll only when keyboard open
                  physics: isKeyboardOpen
                      ? const BouncingScrollPhysics()
                      : const NeverScrollableScrollPhysics(),

                  padding: const EdgeInsets.symmetric(horizontal: 24),

                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),

                    child: Column(
                      children: [

                        /// HEADER
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back),
                            ),
                            const Text(
                              "Forgot Password",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),

                        /// 🔥 SHIFT UP (not center)
                        SizedBox(
                          height: constraints.maxHeight - 80,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [

                              const SizedBox(height: 40), // 🔥 shift up control

                              const Text(
                                "Forgot Password",
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 10),

                              const Text(
                                "Please enter your email and we will send you a link to return to your account",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.black54,
                                ),
                              ),

                              const SizedBox(height: 30),

                              /// EMAIL FIELD
                              TextField(
                                controller: _emailController,
                                focusNode: _emailFocus,
                                keyboardType:
                                    TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  labelText: "Email",
                                  hintText: "Enter Your Email",
                                  prefixIcon: const Icon(Icons.email_outlined, size: 20),

                                  filled: true,
                                  fillColor: Colors.white,

                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                          vertical: 14,
                                          horizontal: 16),

                                  border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(30),
                                  ),

                                  focusedBorder: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(30),
                                    borderSide: const BorderSide(
                                      color: Colors.blue,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 25),

                              /// BUTTON
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _isLoading
                                      ? null
                                      : _sendResetEmail,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color(0xFF2E7D32),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(30),
                                    ),
                                  ),
                                  child: const Text(
                                    "Continue",
                                    style: TextStyle(fontSize: 15),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 25),

                              /// SIGN UP LINK
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    "Don't have an account? ",
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.pushNamed(
                                          context, '/signup');
                                    },
                                    child: const Text(
                                      "Sign Up",
                                      style: TextStyle(
                                        color: Color(0xFF2E7D32),
                                        fontWeight:
                                            FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
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
}
