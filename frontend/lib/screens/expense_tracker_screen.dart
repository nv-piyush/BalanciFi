import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/expense_service.dart';
import '../services/device_service.dart';

class ExpenseTrackerScreen extends StatefulWidget {
  const ExpenseTrackerScreen({super.key});

  @override
  State<ExpenseTrackerScreen> createState() => _ExpenseTrackerScreenState();
}

class _ExpenseTrackerScreenState extends State<ExpenseTrackerScreen> {
  final ExpenseService _expenseService = ExpenseService();
  final DeviceService _deviceService = DeviceService();
  String _currentCurrency = 'USD';

  @override
  void initState() {
    super.initState();
    _initializeCurrency();
  }

  Future<void> _initializeCurrency() async {
    try {
      final currency = await _deviceService.getCurrencyFromLocation();
      setState(() {
        _currentCurrency = currency;
      });
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddExpenseDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Current month's budget overview
          _buildBudgetOverview(),

          // Expense list
          Expanded(
            child: StreamBuilder(
              stream: _expenseService.getExpenses(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final expenses = snapshot.data!.docs;
                if (expenses.isEmpty) {
                  return const Center(child: Text('No expenses yet'));
                }

                return ListView.builder(
                  itemCount: expenses.length,
                  itemBuilder: (context, index) {
                    final expense =
                        expenses[index].data() as Map<String, dynamic>;
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(expense['category'][0]),
                      ),
                      title: Text(expense['description']),
                      subtitle: Text(expense['category']),
                      trailing: Text(
                        '${_currentCurrency} ${expense['amount'].toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetOverview() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Monthly Budget',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            StreamBuilder(
              stream: _expenseService.getExpenses(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                double totalSpent = 0;
                for (var doc in snapshot.data!.docs) {
                  totalSpent +=
                      (doc.data() as Map<String, dynamic>)['amount'] as double;
                }

                return Column(
                  children: [
                    LinearProgressIndicator(
                      value: totalSpent /
                          1000, // Assuming 1000 is the monthly budget
                      backgroundColor: Colors.grey[200],
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Spent: $_currentCurrency ${totalSpent.toStringAsFixed(2)} / 1000',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddExpenseDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Expense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Description'),
              onChanged: (value) {
                // Handle description input
              },
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Amount'),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                // Handle amount input
              },
            ),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Category'),
              items: const [
                DropdownMenuItem(value: 'Food', child: Text('Food')),
                DropdownMenuItem(
                    value: 'Transportation', child: Text('Transportation')),
                DropdownMenuItem(
                    value: 'Entertainment', child: Text('Entertainment')),
                DropdownMenuItem(value: 'Other', child: Text('Other')),
              ],
              onChanged: (value) {
                // Handle category selection
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Add expense logic
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
