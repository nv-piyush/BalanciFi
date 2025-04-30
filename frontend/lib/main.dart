import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: 'AIzaSyBYu6J4haL7KulB7FX3DaBPRoD-8RmBO0o',
      authDomain: 'balancifi-457623.firebaseapp.com',
      projectId: 'balancifi-457623',
      storageBucket: 'balancifi-457623.firebasestorage.app',
      messagingSenderId: '655962644721',
      appId: '1:655962644721:web:cb993148b33f84de968950',
      measurementId: 'G-0YQB6X7VHW',
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
