import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BudgetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get user's budgets
  Stream<QuerySnapshot> getUserBudgets() {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');
    
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('budgets')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Add new budget
  Future<void> addBudget({
    required String category,
    required double limit,
    bool rollover = false,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    // Calculate initial spent amount from existing expenses
    final expensesSnapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('expenses')
        .where('category', isEqualTo: category)
        .get();

    double initialSpent = 0.0;
    for (var doc in expensesSnapshot.docs) {
      initialSpent += (doc.data()['amount'] as num).toDouble();
    }

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('budgets')
        .add({
      'category': category,
      'limit': limit,
      'spent': initialSpent,
      'rollover': rollover,
      'isPaused': false,
      'createdAt': FieldValue.serverTimestamp(),
      'lastReset': FieldValue.serverTimestamp(),
    });
  }

  // Update budget
  Future<void> updateBudget({
    required String budgetId,
    String? category,
    double? limit,
    bool? rollover,
    bool? isPaused,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final updates = <String, dynamic>{};
    
    if (category != null) updates['category'] = category;
    if (limit != null) updates['limit'] = limit;
    if (rollover != null) updates['rollover'] = rollover;
    if (isPaused != null) updates['isPaused'] = isPaused;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('budgets')
        .doc(budgetId)
        .update(updates);
  }

  // Delete budget
  Future<void> deleteBudget(String budgetId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('budgets')
        .doc(budgetId)
        .delete();
  }

  // Reset budget
  Future<void> resetBudget(String budgetId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    // Get the budget category
    final budgetDoc = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('budgets')
        .doc(budgetId)
        .get();

    if (budgetDoc.exists) {
      final category = budgetDoc.data()!['category'] as String;
      
      // Calculate current spent amount from expenses
      final expensesSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('expenses')
          .where('category', isEqualTo: category)
          .get();

      double currentSpent = 0.0;
      for (var doc in expensesSnapshot.docs) {
        currentSpent += (doc.data()['amount'] as num).toDouble();
      }

      // Update budget with current spent amount
      await budgetDoc.reference.update({
        'spent': currentSpent,
        'lastReset': FieldValue.serverTimestamp(),
      });
    }
  }

  // Update spent amount when expense is added
  Future<void> updateSpentAmount(String category, double amount) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    // Find budget with matching category
    final budgetsSnapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('budgets')
        .where('category', isEqualTo: category)
        .get();

    if (budgetsSnapshot.docs.isNotEmpty) {
      final budgetDoc = budgetsSnapshot.docs.first;
      await budgetDoc.reference.update({
        'spent': FieldValue.increment(amount),
      });
    }
  }

  // Get total spent amount for a category
  Future<double> getTotalSpentForCategory(String category) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final expensesSnapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('expenses')
        .where('category', isEqualTo: category)
        .get();

    double totalSpent = 0.0;
    for (var doc in expensesSnapshot.docs) {
      totalSpent += (doc.data()['amount'] as num).toDouble();
    }

    return totalSpent;
  }

  // Sync budget spent amount with expenses
  Future<void> syncBudgetWithExpenses() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final budgetsSnapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('budgets')
        .get();

    for (var budgetDoc in budgetsSnapshot.docs) {
      final category = budgetDoc.data()['category'] as String;
      final totalSpent = await getTotalSpentForCategory(category);
      
      await budgetDoc.reference.update({
        'spent': totalSpent,
      });
    }
  }

  // Check if budget needs reset based on month
  Future<void> checkAndResetBudgets() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final budgets = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('budgets')
        .get();

    final now = DateTime.now();
    
    for (var doc in budgets.docs) {
      final data = doc.data();
      final lastReset = (data['lastReset'] as Timestamp?)?.toDate();
      final rollover = (data['rollover'] as bool?) ?? false;
      final category = data['category'] as String;
      
      // Check if we're in a new month
      if (lastReset != null && now.month != lastReset.month) {
        if (rollover) {
          // Carry over unused amount to next month
          final remaining = (data['limit'] as double) - (data['spent'] as double);
          if (remaining > 0) {
            await doc.reference.update({
              'limit': FieldValue.increment(remaining),
              'spent': 0.0,
              'lastReset': FieldValue.serverTimestamp(),
            });
          } else {
            await resetBudget(doc.id);
          }
        } else {
          await resetBudget(doc.id);
        }
      }
    }
  }

  // Get budget alerts
  Stream<List<Map<String, dynamic>>> getBudgetAlerts() {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('budgets')
        .snapshots()
        .map((snapshot) {
      final alerts = <Map<String, dynamic>>[];
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final spent = data['spent'] as double;
        final limit = data['limit'] as double;
        final progress = spent / limit;
        
        if (progress >= 1.0) {
          alerts.add({
            'budgetId': doc.id,
            'category': data['category'],
            'message': 'Budget exceeded!',
            'severity': 'high',
          });
        } else if (progress >= 0.75) {
          alerts.add({
            'budgetId': doc.id,
            'category': data['category'],
            'message': 'Budget nearly exceeded!',
            'severity': 'medium',
          });
        } else if (progress >= 0.5) {
          alerts.add({
            'budgetId': doc.id,
            'category': data['category'],
            'message': 'Half of budget spent',
            'severity': 'low',
          });
        }
      }
      
      return alerts;
    });
  }

  // Get all budgets
  Future<List<Map<String, dynamic>>> getBudgets() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final budgetsSnapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('budgets')
        .get();

    return budgetsSnapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'category': data['category'] as String,
        'limit': data['limit'] as num,
        'spent': data['spent'] as num,
      };
    }).toList();
  }
} 