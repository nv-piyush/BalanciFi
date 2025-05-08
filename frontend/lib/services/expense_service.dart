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

  // Get current user's expenses for a specific month
  Stream<QuerySnapshot> getMonthlyExpenses(DateTime month) {
    final user = _auth.currentUser;
    if (user != null) {
      // Calculate start and end of the month
      final startOfMonth = DateTime(month.year, month.month, 1, 0, 0, 0);
      final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

      print('DEBUG: Fetching expenses for month: ${month.year}-${month.month}');
      print('DEBUG: Start date: $startOfMonth');
      print('DEBUG: End date: $endOfMonth');
      print('DEBUG: User ID: ${user.uid}');

      final query = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('expenses')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .orderBy('date', descending: true);

      print('DEBUG: Query path: ${query.parameters}');

      return query.snapshots().map((snapshot) {
        print('DEBUG: Got ${snapshot.docs.length} expenses');
        snapshot.docs.forEach((doc) {
          final data = doc.data();
          print('DEBUG: Expense - Date: ${(data['date'] as Timestamp).toDate()}, Amount: ${data['amount']}, Title: ${data['title']}');
        });
        return snapshot;
      });
    }
    throw Exception('No user logged in');
  }

  // Validate expense date is not in the future
  bool isValidExpenseDate(DateTime date) {
    final now = DateTime.now();
    // Strip time component for comparison
    final todayStart = DateTime(now.year, now.month, now.day);
    final dateToCheck = DateTime(date.year, date.month, date.day);
    return dateToCheck.compareTo(todayStart) <= 0;
  }

  // Add new expense with date validation
  Future<void> addExpense({
    required String title,
    required String category,
    required double amount,
    DateTime? date,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final expenseDate = date ?? DateTime.now();
    
    // Strict date validation
    if (!isValidExpenseDate(expenseDate)) {
      throw Exception('Cannot add expenses with future dates');
    }

    final expenseData = {
      'title': title,
      'category': category,
      'amount': amount,
      'date': Timestamp.fromDate(expenseDate),
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

  // Helper function to add test data
  Future<void> addTestExpenses() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final now = DateTime.now();
    
    // Add expenses for current month
    await addExpense(
      title: 'Groceries',
      category: 'Food',
      amount: 150.0,
      date: DateTime(now.year, now.month, 15),
    );
    
    await addExpense(
      title: 'Movie Night',
      category: 'Entertainment',
      amount: 50.0,
      date: DateTime(now.year, now.month, 10),
    );

    // Add expenses for last month
    await addExpense(
      title: 'Restaurant',
      category: 'Food',
      amount: 80.0,
      date: DateTime(now.year, now.month - 1, 20),
    );
    
    await addExpense(
      title: 'Shopping',
      category: 'Shopping',
      amount: 200.0,
      date: DateTime(now.year, now.month - 1, 5),
    );

    // Add expenses for two months ago
    await addExpense(
      title: 'Utilities',
      category: 'Bills',
      amount: 120.0,
      date: DateTime(now.year, now.month - 2, 25),
    );
    
    await addExpense(
      title: 'Gas',
      category: 'Transport',
      amount: 45.0,
      date: DateTime(now.year, now.month - 2, 12),
    );
  }
}
