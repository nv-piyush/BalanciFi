import 'package:flutter/material.dart';
import '../services/reward_service.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  final RewardService _rewardService = RewardService();
  int _totalPoints = 0;

  @override
  void initState() {
    super.initState();
    _loadPoints();
  }

  Future<void> _loadPoints() async {
    final points = await _rewardService.getTotalPoints();
    setState(() {
      _totalPoints = points;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rewards & Achievements'),
      ),
      body: Column(
        children: [
          // Points overview
          _buildPointsOverview(),

          // Achievements
          Expanded(
            child: FutureBuilder(
              future: _rewardService.getAchievementBadges(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final achievements = snapshot.data!;
                if (achievements.isEmpty) {
                  return const Center(child: Text('No achievements yet'));
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: achievements.length,
                  itemBuilder: (context, index) {
                    final achievement = achievements[index];
                    return _buildAchievementCard(achievement);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsOverview() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Your Points',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _totalPoints.toString(),
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.amber,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Keep saving to earn more points!',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementCard(Map<String, dynamic> achievement) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getAchievementIcon(achievement['icon']),
              size: 48,
              color: Colors.amber,
            ),
            const SizedBox(height: 8),
            Text(
              achievement['name'],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              achievement['description'],
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getAchievementIcon(String iconName) {
    switch (iconName) {
      case 'master_badge':
        return Icons.star;
      case 'budget_badge':
        return Icons.account_balance_wallet;
      case 'savings_badge':
        return Icons.savings;
      default:
        return Icons.emoji_events;
    }
  }
}
