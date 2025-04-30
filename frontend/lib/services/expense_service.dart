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
          .collection('expenses')
          .where('userId', isEqualTo: user.uid)
          .orderBy('date', descending: true)
          .snapshots();
    }
    throw Exception('No user logged in');
  }

  // Add new expense with automatic categorization
  Future<void> addExpense({
    required double amount,
    required String description,
    required DateTime date,
    String? category,
    String? receiptUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    // AI-based categorization logic will be implemented here
    final autoCategory = category ?? await _categorizeExpense(description);

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('expenses')
        .add({
      'amount': amount,
      'description': description,
      'date': date,
      'category': autoCategory,
      'receiptUrl': receiptUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });
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
    if (user != null) {
      await _firestore.collection('expenses').doc(expenseId).delete();
    } else {
      throw Exception('No user logged in');
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
    if (user != null) {
      await _firestore.collection('expenses').doc(expenseId).update({
        'title': title,
        'amount': amount,
        'category': category,
        'updatedAt': Timestamp.now(),
      });
    } else {
      throw Exception('No user logged in');
    }
  }
}
