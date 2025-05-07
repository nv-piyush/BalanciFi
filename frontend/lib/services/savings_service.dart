import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SavingsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get user's savings goals
  Stream<QuerySnapshot> getUserSavings() {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');
    
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('savings')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Add new savings goal
  Future<void> addSavingsGoal({
    required String goalName,
    required double targetAmount,
    required DateTime dueDate,
    String? description,
    Map<String, dynamic>? autoTransfer,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final data = {
      'goalName': goalName,
      'targetAmount': targetAmount,
      'currentAmount': 0.0,
      'dueDate': dueDate,
      'description': description,
      'isPaused': false,
      'autoTransfer': autoTransfer ?? {
        'enabled': false,
        'amount': 0.0,
        'frequency': 'monthly',
        'nextRun': calculateNextRunDate('monthly'),
      },
      'createdAt': FieldValue.serverTimestamp(),
    };

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('savings')
        .add(data);
  }

  // Update savings goal
  Future<void> updateSavingsGoal({
    required String goalId,
    String? goalName,
    double? targetAmount,
    DateTime? dueDate,
    String? description,
    bool? isPaused,
    Map<String, dynamic>? autoTransfer,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final updates = <String, dynamic>{};
    
    if (goalName != null) updates['goalName'] = goalName;
    if (targetAmount != null) updates['targetAmount'] = targetAmount;
    if (dueDate != null) updates['dueDate'] = dueDate;
    if (description != null) updates['description'] = description;
    if (isPaused != null) updates['isPaused'] = isPaused;
    if (autoTransfer != null) updates['autoTransfer'] = autoTransfer;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('savings')
        .doc(goalId)
        .update(updates);
  }

  // Delete savings goal
  Future<void> deleteSavingsGoal(String goalId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('savings')
        .doc(goalId)
        .delete();
  }

  // Add contribution to savings goal
  Future<void> addContribution({
    required String goalId,
    required double amount,
    String? description,
    DateTime? date,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final goalDoc = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('savings')
        .doc(goalId)
        .get();

    if (goalDoc.exists) {
      final data = goalDoc.data()!;
      final currentAmount = data['currentAmount'] as double;
      final targetAmount = data['targetAmount'] as double;

      if (currentAmount + amount > targetAmount) {
        throw Exception('Contribution would exceed target amount');
      }

      // Update the savings goal
      await goalDoc.reference.update({
        'currentAmount': FieldValue.increment(amount),
      });

      // Add contribution to history
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('savings')
          .doc(goalId)
          .collection('contributions')
          .add({
        'amount': amount,
        'description': description,
        'date': date ?? FieldValue.serverTimestamp(),
        'type': 'manual',
      });
    }
  }

  // Get contribution history for a savings goal
  Stream<QuerySnapshot> getContributionHistory(String goalId) {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('savings')
        .doc(goalId)
        .collection('contributions')
        .orderBy('date', descending: true)
        .snapshots();
  }

  // Toggle auto-transfer for a savings goal
  Future<void> toggleAutoTransfer({
    required String goalId,
    required bool enabled,
    double? amount,
    String? frequency,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final updates = <String, dynamic>{
      'autoTransfer.enabled': enabled,
    };

    if (amount != null) updates['autoTransfer.amount'] = amount;
    if (frequency != null) updates['autoTransfer.frequency'] = frequency;
    if (enabled) {
      updates['autoTransfer.nextRun'] = calculateNextRunDate(frequency ?? 'monthly');
    }

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('savings')
        .doc(goalId)
        .update(updates);
  }

  // Calculate next run date for auto-transfer
  DateTime calculateNextRunDate(String frequency) {
    final now = DateTime.now();
    switch (frequency.toLowerCase()) {
      case 'daily':
        return now.add(Duration(days: 1));
      case 'weekly':
        return now.add(Duration(days: 7));
      case 'monthly':
        return DateTime(now.year, now.month + 1, now.day);
      default:
        return now.add(Duration(days: 30));
    }
  }

  // Get milestone progress
  Map<String, bool> getMilestoneProgress(double currentAmount, double targetAmount) {
    final progress = currentAmount / targetAmount;
    return {
      '25%': progress >= 0.25,
      '50%': progress >= 0.50,
      '75%': progress >= 0.75,
      '100%': progress >= 1.0,
    };
  }

  // Calculate milestone progress as a percentage
  double calculateMilestoneProgress(double currentAmount, double targetAmount) {
    return (currentAmount / targetAmount).clamp(0.0, 1.0);
  }

  // Calculate days remaining until due date
  int calculateDaysRemaining(DateTime dueDate) {
    final now = DateTime.now();
    return dueDate.difference(now).inDays;
  }
}
