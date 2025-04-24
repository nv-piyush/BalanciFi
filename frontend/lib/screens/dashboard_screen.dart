import 'package:flutter/material.dart';

class DashboardScreen extends StatefulWidget {
  final Function(bool) onThemeChange;
  DashboardScreen({required this.onThemeChange});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  // Temporary placeholder screens
  Widget _buildPlaceholderScreen(String title) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction, size: 64),
          SizedBox(height: 16),
          Text(
            '$title Screen\nComing Soon',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('BalanciFi Dashboard'),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildPlaceholderScreen('Expenses'),
          _buildPlaceholderScreen('Budgets'),
          _buildPlaceholderScreen('Savings'),
          _buildPlaceholderScreen('Insights'),
          _buildPlaceholderScreen('Profile'),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType
            .fixed, // This is needed for more than 3 items
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.money), label: 'Expenses'),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet), label: 'Budgets'),
          BottomNavigationBarItem(icon: Icon(Icons.savings), label: 'Savings'),
          BottomNavigationBarItem(
              icon: Icon(Icons.insights), label: 'Insights'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        onTap: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
