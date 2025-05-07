import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'budget_screen.dart';
import 'savings_screen.dart';
import 'insights_screen.dart';
import 'profile_screen.dart';
import 'add_expense_screen.dart';
import '../services/budget_service.dart';
import '../services/expense_service.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _expenseService = ExpenseService();
  final _budgetService = BudgetService();
  late DateTime selectedDate;
  String searchQuery = '';
  List<Transaction> transactions = [];
  bool isLoading = true;
  String? error;
  StreamSubscription<QuerySnapshot>? _expensesSubscription;
  late ScaffoldMessengerState _scaffoldMessenger;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scaffoldMessenger = ScaffoldMessenger.of(context);
  }

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    _setupExpensesListener();
    _syncBudgetsWithExpenses();
  }

  void _setupExpensesListener() {
    try {
      _expensesSubscription?.cancel();
      _expensesSubscription = _expenseService
          .getMonthlyExpenses(selectedDate)
          .listen(
        (snapshot) {
          if (!mounted) return;
          setState(() {
            transactions = snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return Transaction(
                title: data['title'] ?? '',
                amount: (data['amount'] ?? 0.0).toDouble(),
                date: (data['date'] as Timestamp).toDate(),
                category: data['category'] ?? 'other',
                icon: _getCategoryIcon(data['category'] ?? 'other'),
                color: _getCategoryColor(data['category'] ?? 'other'),
              );
            }).toList();
            isLoading = false;
          });
        },
        onError: (error) {
          print('DEBUG: Error in expenses listener: $error');
          if (!mounted) return;
          setState(() {
            this.error = 'Failed to load expenses: ${error.toString()}';
            isLoading = false;
          });
        },
      );
    } catch (e) {
      print('DEBUG: Exception in _setupExpensesListener: $e');
      if (mounted) {
        setState(() {
          error = 'Error: $e';
          isLoading = false;
        });
      }
    }
  }

  Future<void> _syncBudgetsWithExpenses() async {
    try {
      await _budgetService.syncBudgetWithExpenses();
    } catch (e) {
      if (mounted) {
        _scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Error syncing budgets: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _expensesSubscription?.cancel();
    super.dispose();
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'entertainment':
        return Icons.movie;
      case 'shopping':
        return Icons.shopping_bag;
      case 'bills':
        return Icons.receipt_long;
      default:
        return Icons.attach_money;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Colors.red;
      case 'transport':
        return Colors.blue;
      case 'entertainment':
        return Colors.purple;
      case 'shopping':
        return Colors.amber;
      case 'bills':
        return Colors.green;
      default:
        return Colors.grey;
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
                    onPressed: _setupExpensesListener,
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
          ).then((_) => _setupExpensesListener()); // Refresh list after adding
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
                _setupExpensesListener(); // Refresh expenses when month changes
              });
            },
            icon: Icon(Icons.chevron_left),
            label: Text(''),
          ),
          Text(
            DateFormat('MMMM yyyy').format(selectedDate),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B4242),
            ),
          ),
          TextButton.icon(
            onPressed: () {
              final now = DateTime.now();
              final nextMonth = DateTime(selectedDate.year, selectedDate.month + 1);
              if (nextMonth.isBefore(DateTime(now.year, now.month + 1))) {
                setState(() {
                  selectedDate = nextMonth;
                  _setupExpensesListener(); // Refresh expenses when month changes
                });
              }
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

  Future<void> _deleteExpense(String expenseId, String category, double amount) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Delete the expense
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('expenses')
          .doc(expenseId)
          .delete();

      // Sync budgets with expenses to ensure accurate spent amounts
      await _syncBudgetsWithExpenses();

      if (mounted) {
        _scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Expense deleted'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                // TODO: Implement undo functionality
              },
            ),
          ),
        );
        _setupExpensesListener(); // Refresh the list
      }
    } catch (e) {
      if (mounted) {
        _scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Error deleting expense: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildTransactionItem(Transaction transaction) {
    return Dismissible(
      key: Key(transaction.title + transaction.date.toString()),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        child: Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Delete Expense'),
              content: Text('Are you sure you want to delete this expense?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text('Delete'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) async {
        try {
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) throw Exception('User not logged in');

          // Find the document ID for this transaction
          final snapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('expenses')
              .where('title', isEqualTo: transaction.title)
              .where('amount', isEqualTo: transaction.amount)
              .where('date', isEqualTo: Timestamp.fromDate(transaction.date))
              .get();

          if (snapshot.docs.isNotEmpty) {
            await _deleteExpense(
              snapshot.docs.first.id,
              transaction.category,
              transaction.amount,
            );
          }
        } catch (e) {
          if (mounted) {
            _scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text('Error deleting expense: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      child: Container(
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
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '\$${transaction.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B4242),
                  fontSize: 16,
                ),
              ),
              IconButton(
                icon: Icon(Icons.more_vert, color: Color(0xFF1B4242)),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text('Delete Expense'),
                          onTap: () async {
                            Navigator.pop(context);
                            try {
                              final user = FirebaseAuth.instance.currentUser;
                              if (user == null) throw Exception('User not logged in');

                              final snapshot = await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(user.uid)
                                  .collection('expenses')
                                  .where('title', isEqualTo: transaction.title)
                                  .where('amount', isEqualTo: transaction.amount)
                                  .where('date', isEqualTo: Timestamp.fromDate(transaction.date))
                                  .get();

                              if (snapshot.docs.isNotEmpty) {
                                await _deleteExpense(
                                  snapshot.docs.first.id,
                                  transaction.category,
                                  transaction.amount,
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                _scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Text('Error deleting expense: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
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
              MaterialPageRoute(builder: (context) => BudgetsScreen()),
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
