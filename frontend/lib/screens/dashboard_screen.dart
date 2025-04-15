import 'package:flutter/material.dart';
import 'expenses_screen.dart';
// import 'budgets_screen.dart';
// import 'savings_screen.dart';
// import 'insights_screen.dart';
// import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  final Function(bool) onThemeChange;
  DashboardScreen({required this.onThemeChange});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _screens.addAll([
      ExpensesScreen(),
      // BudgetsScreen(),
      // SavingsScreen(),
      // InsightsScreen(),
      // ProfileScreen(onThemeChange: widget.onThemeChange),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('BalanciFi Dashboard'),
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.money), label: 'Expenses'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Budgets'),
          BottomNavigationBarItem(icon: Icon(Icons.savings), label: 'Savings'),
          BottomNavigationBarItem(icon: Icon(Icons.insights), label: 'Insights'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        onTap: (int index) {
          setState(() { _currentIndex = index; });
        },
      ),
    );
  }
}
