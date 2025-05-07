import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RewardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Award points for meeting budget goals
  Future<void> awardBudgetPoints({
    required String goalId,
    required int points,
    required String achievementType,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('rewards')
        .add({
      'points': points,
      'achievementType': achievementType,
      'goalId': goalId,
      'awardedAt': FieldValue.serverTimestamp(),
    });

    // Update user's total points
    await _updateUserPoints(points);
  }

  // Award points for savings achievements
  Future<void> awardSavingsPoints({
    required String savingsGoalId,
    required int points,
    required String achievementType,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('rewards')
        .add({
      'points': points,
      'achievementType': achievementType,
      'savingsGoalId': savingsGoalId,
      'awardedAt': FieldValue.serverTimestamp(),
    });

    // Update user's total points
    await _updateUserPoints(points);
  }

  // Get user's reward history
  Stream<QuerySnapshot> getRewardHistory() {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('rewards')
        .orderBy('awardedAt', descending: true)
        .snapshots();
  }

  // Get user's total points
  Future<int> getTotalPoints() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    return userDoc.data()?['totalPoints'] ?? 0;
  }

  // Update user's total points
  Future<void> _updateUserPoints(int points) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    await _firestore.collection('users').doc(user.uid).update({
      'totalPoints': FieldValue.increment(points),
    });
  }

  // Get achievement badges
  Future<List<Map<String, dynamic>>> getAchievementBadges() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final rewards = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('rewards')
        .get();

    // Calculate achievements based on reward history
    final achievements = <Map<String, dynamic>>[];
    int totalPoints = 0;
    int budgetGoalsMet = 0;
    int savingsGoalsMet = 0;

    for (var doc in rewards.docs) {
      final data = doc.data();
      totalPoints += data['points'] as int;

      if (data['achievementType'] == 'budget_goal') {
        budgetGoalsMet++;
      } else if (data['achievementType'] == 'savings_goal') {
        savingsGoalsMet++;
      }
    }

    // Add achievements based on criteria
    if (totalPoints >= 1000) {
      achievements.add({
        'name': 'Financial Master',
        'description': 'Earned 1000 points',
        'icon': 'master_badge',
      });
    }

    if (budgetGoalsMet >= 5) {
      achievements.add({
        'name': 'Budget Pro',
        'description': 'Met 5 budget goals',
        'icon': 'budget_badge',
      });
    }

    if (savingsGoalsMet >= 3) {
      achievements.add({
        'name': 'Savings Champion',
        'description': 'Met 3 savings goals',
        'icon': 'savings_badge',
      });
    }

    return achievements;
  }
}
