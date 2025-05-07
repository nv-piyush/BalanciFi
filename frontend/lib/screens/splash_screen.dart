import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo container
            Container(
              width: 200,
              height: 200,
              child: Icon(
                Icons.account_balance_wallet,
                size: 100,
                color: AppTheme.primaryColor,
              ),
            ),
            SizedBox(height: 16),
            // App name
            Text(
              'BALANCIFI',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: 8),
            // Tagline
            Text(
              'Your Money, Your Balance',
              style: TextStyle(
                color: AppTheme.textColor,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
