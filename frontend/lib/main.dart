import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(BalanciFiApp());
}

class BalanciFiApp extends StatefulWidget {
  @override
  _BalanciFiAppState createState() => _BalanciFiAppState();
}

class _BalanciFiAppState extends State<BalanciFiApp> {
  bool darkMode = false; // User setting for dark mode

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BalanciFi',
      theme: darkMode ? ThemeData.dark() : ThemeData.light(),
      home: AuthWrapper(onThemeChange: (bool value) {
        setState(() {
          darkMode = value;
        });
      }),
      routes: {
        '/login': (_) => LoginScreen(),
        '/dashboard': (_) => DashboardScreen(onThemeChange: (bool value) {
          setState(() {
            darkMode = value;
          });
        }),
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
          return snapshot.data == null ? LoginScreen() : DashboardScreen(onThemeChange: onThemeChange);
        }
        return Center(child: CircularProgressIndicator());
      },
    );
  }
}
