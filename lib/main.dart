import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

// Pages
import 'features/splash/splash_page.dart';
import 'features/auth/welcome_page.dart';
import 'features/auth/login_page.dart';
import 'features/auth/signup_page.dart';
import 'features/auth/reset_password_page.dart';
import 'features/home/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const AgroXApp());
}

class AgroXApp extends StatelessWidget {
  const AgroXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      /// 🔥 ENTRY POINT
      home: const AuthWrapper(),

      routes: {
        '/welcome': (context) => const WelcomePage(),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/home': (context) => const HomePage(),
        '/reset-password': (context) => const ResetPasswordPage(),
      },
    );
  }
}

///////////////////////////////////////////////////////////////
/// 🔥 AUTH WRAPPER (AUTO LOGIN SYSTEM)
///////////////////////////////////////////////////////////////

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();

    /// Show splash 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        _showSplash = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    /// 🔥 Show splash first
    if (_showSplash) {
      return const SplashPage();
    }

    /// 🔥 Then listen auth state
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {

        /// Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashPage();
        }

        /// Logged in
        if (snapshot.hasData) {
          return const HomePage();
        }

        /// Not logged
        return const WelcomePage();
      },
    );
  }
}
