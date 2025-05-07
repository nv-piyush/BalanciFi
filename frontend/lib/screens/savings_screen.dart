import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/savings_service.dart';
import 'add_savings_screen.dart';
import 'add_contribution_screen.dart';

class SavingsScreen extends StatefulWidget {
  @override
  _SavingsScreenState createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> {
  final SavingsService _savingsService = SavingsService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Savings Goals',
          style: TextStyle(
            color: Color(0xFF1B4242),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _savingsService.getUserSavings(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading savings goals: ${snapshot.error}',
                style: TextStyle(color: Colors.red),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.savings_outlined,
                    size: 64,
                    color: Color(0xFF1B4242).withOpacity(0.5),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No savings goals yet',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap + to create your first goal',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final goalName = data['goalName'] ?? '';
              final targetAmount = data['targetAmount'] ?? 0.0;
              final currentAmount = data['currentAmount'] ?? 0.0;
              final dueDate = (data['dueDate'] as Timestamp?)?.toDate();
              final progress = currentAmount / targetAmount;
              final daysRemaining = dueDate != null
                  ? _savingsService.calculateDaysRemaining(dueDate)
                  : 0;
              final rawAutoTransfer = data['autoTransfer'];
              final autoTransfer = rawAutoTransfer is Map<String, dynamic> ? rawAutoTransfer : null;
              final isAutoTransferEnabled = autoTransfer?['enabled'] ?? false;
              final nextRun = (autoTransfer?['nextRun'] as Timestamp?)?.toDate();
              final milestones = _savingsService.getMilestoneProgress(
                currentAmount,
                targetAmount,
              );

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                margin: EdgeInsets.only(bottom: 16),
                child: InkWell(
                  onTap: () {
                    _showSavingsDetails(context, doc);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Color(0xFF1B4242).withOpacity(0.1),
                              child: Icon(
                                Icons.savings,
                                color: Color(0xFF1B4242),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    goalName,
                                    style: TextStyle(
                                      color: Color(0xFF1B4242),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '\$${currentAmount.toStringAsFixed(2)} / \$${targetAmount.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isAutoTransferEnabled)
                              Icon(
                                Icons.autorenew,
                                color: Color(0xFF1B4242),
                                size: 20,
                              ),
                          ],
                        ),
                        SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getProgressColor(progress),
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${(progress * 100).toStringAsFixed(1)}%',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            if (dueDate != null)
                              Text(
                                '$daysRemaining days left',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildMilestoneIcon(milestones['25%']!, '25%'),
                            _buildMilestoneIcon(milestones['50%']!, '50%'),
                            _buildMilestoneIcon(milestones['75%']!, '75%'),
                            _buildMilestoneIcon(milestones['100%']!, '100%'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'savings_add_fab',
        backgroundColor: Color(0xFF1B4242),
        child: Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddSavingsScreen()),
          );
        },
      ),
    );
  }

  Widget _buildMilestoneIcon(bool achieved, String milestone) {
    return Column(
      children: [
        Icon(
          achieved ? Icons.emoji_events : Icons.emoji_events_outlined,
          color: achieved ? Color(0xFF1B4242) : Colors.grey[400],
          size: 20,
        ),
        Text(
          milestone,
          style: TextStyle(
            color: achieved ? Color(0xFF1B4242) : Colors.grey[400],
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Color _getProgressColor(double progress) {
    if (progress >= 1.0) return Colors.green;
    if (progress >= 0.75) return Color(0xFF1B4242);
    if (progress >= 0.5) return Colors.blue;
    return Colors.orange;
  }

  void _showSavingsDetails(BuildContext context, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final goalName = data['goalName'] ?? '';
    final targetAmount = data['targetAmount'] ?? 0.0;
    final currentAmount = data['currentAmount'] ?? 0.0;
    final dueDate = (data['dueDate'] as Timestamp?)?.toDate();
    final autoTransferData = data['autoTransfer'];
    final autoTransfer = autoTransferData is Map<String, dynamic> ? autoTransferData : null;
    final isAutoTransferEnabled = autoTransfer?['enabled'] ?? false;
    final autoTransferAmount = autoTransfer?['amount'] ?? 0.0;
    final autoTransferFrequency = autoTransfer?['frequency'] ?? '';
    final nextRun = (autoTransfer?['nextRun'] as Timestamp?)?.toDate();
    final milestones = _savingsService.getMilestoneProgress(
      currentAmount,
      targetAmount,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              goalName,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B4242),
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Current Amount',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                Text(
                  '\$${currentAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B4242),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Target Amount',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                Text(
                  '\$${targetAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B4242),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            if (dueDate != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Due Date',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  Text(
                    '${dueDate.day}/${dueDate.month}/${dueDate.year}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B4242),
                    ),
                  ),
                ],
              ),
            if (isAutoTransferEnabled) ...[
              SizedBox(height: 16),
              Text(
                'Auto-Transfer Settings',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B4242),
                ),
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Amount',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  Text(
                    '\$${autoTransferAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B4242),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Frequency',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  Text(
                    autoTransferFrequency.capitalize(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B4242),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              if (nextRun != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Next Transfer',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    Text(
                      '${nextRun.day}/${nextRun.month}/${nextRun.year}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B4242),
                      ),
                    ),
                  ],
                ),
            ],
            SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.add, color: Color(0xFF1B4242)),
              title: Text('Add Contribution'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddContributionScreen(goalId: doc.id),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.edit, color: Color(0xFF1B4242)),
              title: Text('Edit Goal'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddSavingsScreen(
                      goalId: doc.id,
                      initialGoalName: goalName,
                      initialTargetAmount: targetAmount,
                      initialDueDate: dueDate,
                      initialAutoTransfer: autoTransfer,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text('Delete Goal', style: TextStyle(color: Colors.red)),
              onTap: () {
                _savingsService.deleteSavingsGoal(doc.id);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}
