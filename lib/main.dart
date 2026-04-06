import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';

// Pages
import 'features/splash/splash_page.dart';
import 'features/auth/welcome_page.dart';
import 'features/auth/login_page.dart';
import 'features/auth/signup_page.dart';
import 'features/auth/reset_password_page.dart';
import 'features/home/home_page.dart';
import 'features/profile/profile_page.dart';

// Knowledge Hub
import 'features/knowledge/knowledge_page.dart';

// ✅ AI Pages
import 'features/home/detect_page.dart';
import 'features/home/chat_page.dart'; // 🔥 ADD THIS

// Theme
import 'services/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const AgroXApp(),
    ),
  );
}

class AgroXApp extends StatelessWidget {
  const AgroXApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AgroX',

      // 🔥 UI WRAPPER (CENTERED)
      builder: (context, child) {
        final data = MediaQuery.of(context);

        return MediaQuery(
          data: data.copyWith(textScaler: const TextScaler.linear(1.0)),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: child!,
              ),
            ),
          ),
        );
      },

      themeMode: themeProvider.themeMode,

      // 🌞 LIGHT THEME
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.green,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        cardColor: Colors.white,
        useMaterial3: true,
      ),

      // 🌙 DARK THEME
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.green,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        cardColor: const Color(0xFF1E1E1E),
        useMaterial3: true,
      ),

      // 🔥 ENTRY
      home: const AuthWrapper(),

      // 🔥 ROUTES
      routes: {
        '/welcome': (context) => const WelcomePage(),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/home': (context) => const HomePage(),
        '/profile': (context) => const ProfilePage(),
        '/reset-password': (context) => const ResetPasswordPage(),

        // 📚 Knowledge Hub
        '/knowledge': (context) => const KnowledgePage(),

        // 🤖 AI Scan Page
        '/scan': (context) => DetectPage(),

        // 🤖 CHATBOT (NEW 🔥🔥🔥)
        '/chatbot': (context) => const ChatPage(), // ✅ THIS FIXES YOUR ERROR
      },
    );
  }
}

///////////////////////////////////////////////////////////////
/// 🔐 AUTH WRAPPER
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

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showSplash = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return const SplashPage();
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashPage();
        }

        if (snapshot.hasData) {
          return const HomePage();
        }

        return const WelcomePage();
      },
    );
  }
}