import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: dotenv.env['FIREBASE_API_KEY'] ?? '',
      authDomain: dotenv.env['FIREBASE_AUTH_DOMAIN'] ?? '',
      projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? '',
      storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '',
      messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '',
      appId: dotenv.env['FIREBASE_APP_ID'] ?? '',
      measurementId: dotenv.env['FIREBASE_MEASUREMENT_ID'] ?? '',
    ),
  );
  runApp(BalanciFiApp());
}

class BalanciFiApp extends StatefulWidget {
  @override
  _BalanciFiAppState createState() => _BalanciFiAppState();
}

class _BalanciFiAppState extends State<BalanciFiApp> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    // Simulate splash screen delay
    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showSplash = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BalanciFi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: Builder(
        builder: (context) {
          if (_showSplash) {
            return SplashScreen();
          }
          return OnboardingScreen();
        },
      ),
      routes: {
        '/login': (context) => LoginScreen(),
        '/dashboard': (context) => DashboardScreen(
              onThemeChange: (bool value) {
                setState(() {
                  // Handle theme change
                });
              },
            ),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  final Function(bool) onThemeChange;
  AuthWrapper({required this.onThemeChange});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          return snapshot.data == null
              ? LoginScreen()
              : DashboardScreen(onThemeChange: onThemeChange);
        }
        return Center(child: CircularProgressIndicator());
      },
    );
  }
}
