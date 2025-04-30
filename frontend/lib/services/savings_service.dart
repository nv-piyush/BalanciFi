import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SavingsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a new savings goal
  Future<void> createSavingsGoal({
    required String title,
    required double targetAmount,
    required DateTime targetDate,
    String? description,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('savings_goals')
        .add({
      'title': title,
      'targetAmount': targetAmount,
      'currentAmount': 0.0,
      'targetDate': targetDate,
      'description': description,
      'createdAt': FieldValue.serverTimestamp(),
      'isCompleted': false,
    });
  }

  // Update savings goal progress
  Future<void> updateSavingsProgress({
    required String goalId,
    required double amount,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final goalRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('savings_goals')
        .doc(goalId);

    await _firestore.runTransaction((transaction) async {
      final goalDoc = await transaction.get(goalRef);
      if (!goalDoc.exists) {
        throw Exception('Goal not found');
      }

      final currentAmount = goalDoc.data()!['currentAmount'] as double;
      final targetAmount = goalDoc.data()!['targetAmount'] as double;
      final newAmount = currentAmount + amount;
      final isCompleted = newAmount >= targetAmount;

      transaction.update(goalRef, {
        'currentAmount': newAmount,
        'isCompleted': isCompleted,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    });
  }

  // Get all savings goals
  Stream<QuerySnapshot> getSavingsGoals() {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('savings_goals')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Get savings recommendations
  Future<Map<String, dynamic>> getSavingsRecommendations() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    // Get user's expenses for the last 3 months
    final threeMonthsAgo = DateTime.now().subtract(const Duration(days: 90));
    final expenses = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('expenses')
        .where('date', isGreaterThanOrEqualTo: threeMonthsAgo)
        .get();

    // Calculate spending patterns
    Map<String, double> categorySpending = {};
    double totalSpent = 0;

    for (var doc in expenses.docs) {
      final data = doc.data();
      final amount = data['amount'] as double;
      final category = data['category'] as String;

      totalSpent += amount;
      categorySpending[category] = (categorySpending[category] ?? 0) + amount;
    }

    // Generate recommendations
    final recommendations = <String, double>{};
    final averageSpending = totalSpent / 3; // Average monthly spending

    categorySpending.forEach((category, amount) {
      if (amount > averageSpending * 0.2) {
        // If category spending is more than 20% of average
        recommendations[category] =
            amount * 0.1; // Suggest saving 10% of that category
      }
    });

    return {
      'totalSpent': totalSpent,
      'averageMonthlySpending': averageSpending,
      'recommendations': recommendations,
    };
  }
}
