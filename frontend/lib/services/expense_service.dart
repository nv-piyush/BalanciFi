import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ExpenseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user's expenses
  Stream<QuerySnapshot> getUserExpenses() {
    final user = _auth.currentUser;
    if (user != null) {
      return _firestore
          .collection('users')
          .doc(user.uid)
          .collection('expenses')
          .orderBy('date', descending: true)
          .snapshots();
    }
    throw Exception('No user logged in');
  }

  // Add new expense
  Future<void> addExpense({
    required String title,
    required double amount,
    required String category,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('expenses')
          .add({
        'title': title,
        'amount': amount,
        'category': category,
        'date': DateTime.now(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding expense: $e');
      throw Exception('Failed to add expense: $e');
    }
  }

  // Get expenses with optional filtering
  Stream<QuerySnapshot> getExpenses({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
  }) {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    Query query =
        _firestore.collection('users').doc(user.uid).collection('expenses');

    if (startDate != null) {
      query = query.where('date', isGreaterThanOrEqualTo: startDate);
    }
    if (endDate != null) {
      query = query.where('date', isLessThanOrEqualTo: endDate);
    }
    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }

    return query.orderBy('date', descending: true).snapshots();
  }

  // AI-based expense categorization
  Future<String> _categorizeExpense(String description) async {
    // TODO: Implement ML-based categorization
    // For now, return a default category
    return 'Other';
  }

  // Get spending insights
  Future<Map<String, dynamic>> getSpendingInsights({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final expenses = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('expenses')
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThanOrEqualTo: endDate)
        .get();

    // Calculate insights
    double totalSpent = 0;
    Map<String, double> categorySpending = {};

    for (var doc in expenses.docs) {
      final data = doc.data();
      final amount = data['amount'] as double;
      final category = data['category'] as String;

      totalSpent += amount;
      categorySpending[category] = (categorySpending[category] ?? 0) + amount;
    }

    return {
      'totalSpent': totalSpent,
      'categorySpending': categorySpending,
      'averageDailySpending':
          totalSpent / (endDate.difference(startDate).inDays + 1),
    };
  }

  // Delete expense
  Future<void> deleteExpense(String expenseId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('expenses')
          .doc(expenseId)
          .delete();
    } catch (e) {
      print('Error deleting expense: $e');
      throw Exception('Failed to delete expense: $e');
    }
  }

  // Update expense
  Future<void> updateExpense({
    required String expenseId,
    required String title,
    required double amount,
    required String category,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('expenses')
          .doc(expenseId)
          .update({
        'title': title,
        'amount': amount,
        'category': category,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating expense: $e');
      throw Exception('Failed to update expense: $e');
    }
  }
}
