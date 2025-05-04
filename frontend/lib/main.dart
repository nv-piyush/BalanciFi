import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/signup_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
            apiKey: "AIzaSyBYu6J4haL7KulB7FX3DaBPRoD-8RmBO0o",
            authDomain: "balancifi-457623.firebaseapp.com",
            projectId: "balancifi-457623",
            storageBucket: "balancifi-457623.appspot.com",
            messagingSenderId: "655962644721",
            appId: "1:655962644721:web:cb993148b33f84de968950",
            measurementId: "G-0YQB6X7VHW"),
      );
    } else {
      await Firebase.initializeApp();
    }
    print('Firebase initialized successfully');

    // Initialize Firestore database
    try {
      final firestore = FirebaseFirestore.instance;
      final expensesRef = firestore.collection('expenses');

      // Just check if we can access the collection
      await expensesRef.limit(1).get();
      print('Successfully connected to Firestore');
    } catch (e) {
      print('Warning: Could not initialize Firestore: $e');
      // Continue app execution even if Firestore initialization fails
    }
  } catch (e) {
    print('Error initializing Firebase: $e');
    // Continue app execution even if Firebase initialization fails
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BalanciFi',
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkFirstTime();
  }

  Future<void> _checkFirstTime() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final isFirstTime = prefs.getBool('isFirstTime') ?? true;

    if (isFirstTime) {
      await prefs.setBool('isFirstTime', false);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => OnboardingScreen(
            onComplete: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ),
      );
    } else {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Temporarily removed logo until asset is available
            const SizedBox(height: 24),
            const Text(
              'BalanciFi',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
