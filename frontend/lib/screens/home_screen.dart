import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'budget_screen.dart';
import 'savings_screen.dart';
import 'insights_screen.dart';
import 'profile_screen.dart';
import 'add_expense_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final user = FirebaseAuth.instance.currentUser;
  DateTime selectedDate = DateTime.now();
  String searchQuery = '';
  List<Transaction> transactions = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      // Placeholder data for now
      setState(() {
        transactions = [
          Transaction(
            title: 'Shopping',
            amount: 54.99,
            date: DateTime.now(),
            category: 'shopping',
            icon: Icons.shopping_bag,
            color: Colors.amber,
          ),
          Transaction(
            title: 'Food Delivery',
            amount: 24.50,
            date: DateTime.now().subtract(Duration(days: 1)),
            category: 'food',
            icon: Icons.delivery_dining,
            color: Colors.red,
          ),
          Transaction(
            title: 'Monthly Reward',
            amount: 15.00,
            date: DateTime.now().subtract(Duration(days: 2)),
            category: 'reward',
            icon: Icons.card_giftcard,
            color: Colors.green,
          ),
        ];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Failed to load transactions. Please try again.';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'BALANCIFI',
          style: TextStyle(
            color: Color(0xFF1B4242),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    error!,
                    style: TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadTransactions,
                    child: Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF1B4242),
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                _buildSearchBar(),
                _buildMonthSelector(),
                Expanded(
                  child: isLoading
                      ? Center(child: CircularProgressIndicator())
                      : _buildTransactionsList(),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddExpenseScreen(),
            ),
          ).then((_) => _loadTransactions()); // Refresh list after adding
        },
        backgroundColor: Color(0xFF1B4242),
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        onChanged: (value) {
          setState(() {
            searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search for expenses...',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: Color(0xFF1B4242)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: Color(0xFF1B4242)),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: () {
              setState(() {
                selectedDate = DateTime(
                  selectedDate.year,
                  selectedDate.month - 1,
                );
              });
            },
            icon: Icon(Icons.chevron_left),
            label: Text(''),
          ),
          Text(
            '${selectedDate.year}-${selectedDate.month}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B4242),
            ),
          ),
          TextButton.icon(
            onPressed: () {
              setState(() {
                selectedDate = DateTime(
                  selectedDate.year,
                  selectedDate.month + 1,
                );
              });
            },
            icon: Icon(Icons.chevron_right),
            label: Text(''),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    return ListView.builder(
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        if (searchQuery.isNotEmpty &&
            !transaction.title
                .toLowerCase()
                .contains(searchQuery.toLowerCase())) {
          return SizedBox.shrink();
        }
        return _buildTransactionItem(transaction);
      },
    );
  }

  Widget _buildTransactionItem(Transaction transaction) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: transaction.color.withOpacity(0.2),
          child: Icon(
            transaction.icon,
            color: transaction.color,
          ),
        ),
        title: Text(
          transaction.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF1B4242),
          ),
        ),
        subtitle: Text(
          '${transaction.date.year}-${transaction.date.month}-${transaction.date.day}',
          style: TextStyle(color: Colors.grey),
        ),
        trailing: Text(
          '\$${transaction.amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B4242),
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Color(0xFF1B4242),
      unselectedItemColor: Colors.grey,
      currentIndex: 0,
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.account_balance_wallet),
          label: 'Expenses',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.pie_chart),
          label: 'Budgets',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.savings),
          label: 'Savings',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.insights),
          label: 'Insights',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
      onTap: (index) {
        switch (index) {
          case 0:
            // Already on expenses screen
            break;
          case 1:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => BudgetScreen()),
            );
            break;
          case 2:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SavingsScreen()),
            );
            break;
          case 3:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => InsightsScreen()),
            );
            break;
          case 4:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProfileScreen()),
            );
            break;
        }
      },
    );
  }
}

class Transaction {
  final String title;
  final double amount;
  final DateTime date;
  final String category;
  final IconData icon;
  final Color color;

  Transaction({
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    required this.icon,
    required this.color,
  });
}
