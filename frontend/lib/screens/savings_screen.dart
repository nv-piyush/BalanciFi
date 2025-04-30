import 'package:flutter/material.dart';

class SavingsScreen extends StatefulWidget {
  @override
  _SavingsScreenState createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Savings Goals',
          style: TextStyle(
            color: Color(0xFF1B4242),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.savings, size: 64, color: Color(0xFF1B4242)),
            SizedBox(height: 16),
            Text(
              'Savings Screen\nComing Soon',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24),
            ),
          ],
        ),
      ),
    );
  }
}
