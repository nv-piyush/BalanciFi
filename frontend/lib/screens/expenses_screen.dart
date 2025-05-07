import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/expense_service.dart';

class ExpensesScreen extends StatefulWidget {
  @override
  _ExpensesScreenState createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final ExpenseService _expenseService = ExpenseService();
  late DateTime _selectedMonth;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize with current month
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
  }

  void _previousMonth() {
    print('DEBUG: Navigating to previous month from ${_selectedMonth.year}-${_selectedMonth.month}');
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
    print('DEBUG: New selected month: ${_selectedMonth.year}-${_selectedMonth.month}');
  }

  void _nextMonth() {
    final now = DateTime.now();
    final nextMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    
    print('DEBUG: Attempting to navigate to next month from ${_selectedMonth.year}-${_selectedMonth.month}');
    // Only allow navigation up to current month
    if (nextMonth.isBefore(DateTime(now.year, now.month + 1))) {
      setState(() {
        _selectedMonth = nextMonth;
      });
      print('DEBUG: New selected month: ${_selectedMonth.year}-${_selectedMonth.month}');
    } else {
      print('DEBUG: Cannot navigate to future month: ${nextMonth.year}-${nextMonth.month}');
    }
  }

  bool _canNavigateNext() {
    final now = DateTime.now();
    final nextMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    return nextMonth.isBefore(DateTime(now.year, now.month + 1));
  }

  void _addExpense() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddExpenseSheet(
        expenseService: _expenseService,
        selectedMonth: _selectedMonth,
        onExpenseAdded: () {
          // Force rebuild to refresh the expenses list
          setState(() {});
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for expenses...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onChanged: (value) {
                // Force rebuild when search text changes
                setState(() {});
              },
            ),
          ),
          // Month selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.chevron_left),
                  onPressed: _previousMonth,
                ),
                Text(
                  DateFormat('yyyy-MM').format(_selectedMonth),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: Icon(Icons.chevron_right),
                  onPressed: _canNavigateNext() ? _nextMonth : null,
                  color: _canNavigateNext() ? null : Colors.grey,
                ),
              ],
            ),
          ),
          // Expenses list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _expenseService.getMonthlyExpenses(_selectedMonth),
              builder: (context, snapshot) {
                print('DEBUG: StreamBuilder rebuild - ConnectionState: ${snapshot.connectionState}');
                if (snapshot.hasError) {
                  print('DEBUG: StreamBuilder error: ${snapshot.error}');
                  return Center(child: Text('Something went wrong'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final expenses = snapshot.data?.docs ?? [];
                print('DEBUG: Got ${expenses.length} expenses from snapshot');
                
                // Filter expenses based on search
                final filteredExpenses = _searchController.text.isEmpty
                    ? expenses
                    : expenses.where((expense) {
                        final data = expense.data() as Map;
                        final title = (data['title'] as String).toLowerCase();
                        final category = (data['category'] as String).toLowerCase();
                        final searchTerm = _searchController.text.toLowerCase();
                        return title.contains(searchTerm) ||
                            category.contains(searchTerm);
                      }).toList();

                double totalExpenses = filteredExpenses.fold(
                  0.0,
                  (sum, expense) => sum + (expense.data() as Map)['amount'],
                );

                return Column(
                  children: [
                    // Summary Card
                    Card(
                      margin: EdgeInsets.all(16),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text(
                              'Monthly Total',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            SizedBox(height: 8),
                            Text(
                              '\$${totalExpenses.toStringAsFixed(2)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Expenses List
                    Expanded(
                      child: filteredExpenses.isEmpty
                          ? Center(
                              child: Text(
                                  'No expenses for ${DateFormat('MMMM yyyy').format(_selectedMonth)}'),
                            )
                          : ListView.builder(
                              itemCount: filteredExpenses.length,
                              itemBuilder: (context, index) {
                                final expense = filteredExpenses[index];
                                final data = expense.data() as Map;
                                final date = (data['date'] as Timestamp).toDate();
                                return Dismissible(
                                  key: Key(expense.id),
                                  background: Container(
                                    color: Colors.red,
                                    alignment: Alignment.centerRight,
                                    padding: EdgeInsets.only(right: 20),
                                    child: Icon(Icons.delete, color: Colors.white),
                                  ),
                                  direction: DismissDirection.endToStart,
                                  onDismissed: (direction) {
                                    _expenseService.deleteExpense(expense.id);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Expense deleted')),
                                    );
                                  },
                                  child: Card(
                                    margin: EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: AppTheme.primaryColor,
                                        child: Icon(
                                          _getCategoryIcon(data['category']),
                                          color: Colors.white,
                                        ),
                                      ),
                                      title: Text(data['title']),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(data['category']),
                                          Text(
                                            DateFormat('MMM d, yyyy').format(date),
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ],
                                      ),
                                      trailing: Text(
                                        '\$${data['amount'].toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addExpense,
        child: Icon(Icons.add),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'shopping':
        return Icons.shopping_bag;
      case 'transport':
        return Icons.directions_car;
      case 'entertainment':
        return Icons.movie;
      case 'bills':
        return Icons.receipt_long;
      case 'health':
        return Icons.health_and_safety;
      case 'education':
        return Icons.school;
      case 'travel':
        return Icons.flight;
      default:
        return Icons.category;
    }
  }
}

class AddExpenseSheet extends StatefulWidget {
  final ExpenseService expenseService;
  final DateTime selectedMonth;
  final VoidCallback onExpenseAdded;

  const AddExpenseSheet({
    required this.expenseService,
    required this.selectedMonth,
    required this.onExpenseAdded,
  });

  @override
  _AddExpenseSheetState createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<AddExpenseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedCategory = 'Food';
  late DateTime _selectedDate;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Initialize with first day of selected month, or current date if it's the current month
    final now = DateTime.now();
    final firstDayOfSelectedMonth = DateTime(widget.selectedMonth.year, widget.selectedMonth.month, 1);
    
    if (widget.selectedMonth.year == now.year && widget.selectedMonth.month == now.month) {
      _selectedDate = now;
    } else {
      _selectedDate = firstDayOfSelectedMonth;
    }
  }

  final List<String> _categories = [
    'Food',
    'Shopping',
    'Transport',
    'Entertainment',
    'Bills',
    'Health',
    'Education',
    'Travel',
    'Other'
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submitExpense() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        // Validate date before submission
        if (!widget.expenseService.isValidExpenseDate(_selectedDate)) {
          throw Exception('Cannot add expenses with future dates');
        }

        await widget.expenseService.addExpense(
          title: _titleController.text,
          amount: double.parse(_amountController.text),
          category: _selectedCategory,
          date: _selectedDate,
        );
        widget.onExpenseAdded();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Expense added successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add expense: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Add New Expense',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an amount';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Category',
                prefixIcon: Icon(Icons.category),
              ),
              items: _categories.map((String category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                }
              },
            ),
            SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.calendar_today),
              title: Text('Date'),
              subtitle: Text(DateFormat('MMM d, yyyy').format(_selectedDate)),
              onTap: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate.isAfter(now) ? now : _selectedDate,
                  firstDate: DateTime(now.year - 1),
                  lastDate: now,
                );
                if (picked != null && picked.compareTo(now) <= 0) {
                  setState(() {
                    _selectedDate = picked;
                  });
                }
              },
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitExpense,
              child: _isSubmitting
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text('Add Expense'),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
