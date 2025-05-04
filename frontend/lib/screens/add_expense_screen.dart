import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';

class AddExpenseScreen extends StatefulWidget {
  @override
  _AddExpenseScreenState createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedCategory = 'Shopping';
  bool _isLoading = false;

  final List<Map<String, dynamic>> categories = [
    {
      'name': 'Shopping',
      'icon': Icons.shopping_bag,
      'color': Colors.amber,
    },
    {
      'name': 'Food',
      'icon': Icons.restaurant,
      'color': Colors.red,
    },
    {
      'name': 'Transport',
      'icon': Icons.directions_car,
      'color': Colors.blue,
    },
    {
      'name': 'Entertainment',
      'icon': Icons.movie,
      'color': Colors.purple,
    },
    {
      'name': 'Bills',
      'icon': Icons.receipt_long,
      'color': Colors.green,
    },
  ];

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      print('Current user: ${user.uid}');
      print('User email: ${user.email}');

      // Get Firestore instance
      final firestore = FirebaseFirestore.instance;

      // Store expense in user's expenses subcollection
      final userExpensesRef =
          firestore.collection('users').doc(user.uid).collection('expenses');

      // Create the expense data
      final now = kIsWeb ? Timestamp.now() : FieldValue.serverTimestamp();

      final expenseData = {
        'title': _titleController.text,
        'amount': double.parse(_amountController.text),
        'category': _selectedCategory,
        'date': now,
        'createdAt': now,
      };

      print('About to add expense: $expenseData');
      final docRef = await userExpensesRef.add(expenseData);
      print('Expense added, docRef: ${docRef.id}');

      // Verify the document was created
      final docSnapshot = await docRef.get();
      if (!docSnapshot.exists) {
        throw Exception('Failed to create expense document');
      }

      print('Expense saved with ID: ${docRef.id}');
      Navigator.pop(context);
    } catch (e) {
      print('Error in _saveExpense: $e');
      if (e is FirebaseException) {
        print('Firebase error code: ${e.code}');
        print('Firebase error message: ${e.message}');
        print('Firebase error details: ${e.toString()}');

        // Handle specific Firebase errors
        String errorMessage = 'Error saving expense';
        if (e.code == 'permission-denied') {
          errorMessage =
              'Permission denied. Please check your authentication status.';
        } else if (e.code == 'not-found') {
          errorMessage = 'Database not found. Please contact support.';
        } else if (e.code == 'unavailable') {
          errorMessage = 'Service unavailable. Please try again later.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving expense: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Color(0xFF1B4242)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Add Expense',
          style: TextStyle(
            color: Color(0xFF1B4242),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
                prefixText: '\$',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
            Text(
              'Category',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories.map((category) {
                bool isSelected = _selectedCategory == category['name'];
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedCategory = category['name'];
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Color(0xFF1B4242)
                          : Color(0xFF1B4242).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          category['icon'],
                          color: isSelected ? Colors.white : Color(0xFF1B4242),
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          category['name'],
                          style: TextStyle(
                            color:
                                isSelected ? Colors.white : Color(0xFF1B4242),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveExpense,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF1B4242),
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Save Expense',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }
}
