import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'budget_service.dart';

class ExpenseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final BudgetService _budgetService = BudgetService();

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
    required String category,
    required double amount,
    required String description,
    DateTime? date,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final expenseData = {
      'category': category,
      'amount': amount,
      'description': description,
      'date': date ?? DateTime.now(),
      'createdAt': FieldValue.serverTimestamp(),
    };

    // Add expense to user's expenses collection
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('expenses')
        .add(expenseData);

    // Update corresponding budget's spent amount
    await _budgetService.updateSpentAmount(category, amount);
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
    if (user == null) throw Exception('User not logged in');

    // Get the expense data before deleting
    final expenseDoc = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('expenses')
        .doc(expenseId)
        .get();

    if (expenseDoc.exists) {
      final data = expenseDoc.data()!;
      final category = data['category'] as String;
      final amount = data['amount'] as double;

      // Delete the expense
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('expenses')
          .doc(expenseId)
          .delete();

      // Update the corresponding budget
      await _budgetService.updateSpentAmount(category, -amount);
    }
  }

  // Update expense
  Future<void> updateExpense({
    required String expenseId,
    String? category,
    double? amount,
    String? description,
    DateTime? date,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final updates = <String, dynamic>{};
    
    if (category != null) updates['category'] = category;
    if (amount != null) updates['amount'] = amount;
    if (description != null) updates['description'] = description;
    if (date != null) updates['date'] = date;

    // Get the old expense data
    final oldExpenseDoc = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('expenses')
        .doc(expenseId)
        .get();

    if (oldExpenseDoc.exists) {
      final oldData = oldExpenseDoc.data()!;
      final oldCategory = oldData['category'] as String;
      final oldAmount = oldData['amount'] as double;

      // Update the expense
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('expenses')
          .doc(expenseId)
          .update(updates);

      // If category or amount changed, update budgets
      if (category != null || amount != null) {
        // Remove old amount from old category
        if (category != oldCategory) {
          await _budgetService.updateSpentAmount(oldCategory, -oldAmount);
        }
        
        // Add new amount to new category
        final newCategory = category ?? oldCategory;
        final newAmount = amount ?? oldAmount;
        await _budgetService.updateSpentAmount(newCategory, newAmount);
      }
    }
  }
}
