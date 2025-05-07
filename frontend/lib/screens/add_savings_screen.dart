import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/savings_service.dart';

class AddSavingsScreen extends StatefulWidget {
  final String? goalId;
  final String? initialGoalName;
  final double? initialTargetAmount;
  final DateTime? initialDueDate;
  final Map<String, dynamic>? initialAutoTransfer;

  const AddSavingsScreen({
    Key? key,
    this.goalId,
    this.initialGoalName,
    this.initialTargetAmount,
    this.initialDueDate,
    this.initialAutoTransfer,
  }) : super(key: key);

  @override
  _AddSavingsScreenState createState() => _AddSavingsScreenState();
}

class _AddSavingsScreenState extends State<AddSavingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _goalNameController = TextEditingController();
  final _targetAmountController = TextEditingController();
  final _autoTransferAmountController = TextEditingController();
  final _savingsService = SavingsService();
  bool _isLoading = false;
  DateTime? _dueDate;
  String _autoTransferFrequency = 'monthly';
  bool _autoTransferEnabled = false;

  final List<String> _frequencies = ['daily', 'weekly', 'monthly'];

  @override
  void initState() {
    super.initState();
    if (widget.initialGoalName != null) {
      _goalNameController.text = widget.initialGoalName!;
    }
    if (widget.initialTargetAmount != null) {
      _targetAmountController.text = widget.initialTargetAmount!.toString();
    }
    if (widget.initialDueDate != null) {
      _dueDate = widget.initialDueDate;
    }
    if (widget.initialAutoTransfer != null) {
      _autoTransferEnabled = widget.initialAutoTransfer!['enabled'] ?? false;
      _autoTransferAmountController.text = 
          (widget.initialAutoTransfer!['amount'] ?? 0.0).toString();
      _autoTransferFrequency = widget.initialAutoTransfer!['frequency'] ?? 'monthly';
    }
  }

  @override
  void dispose() {
    _goalNameController.dispose();
    _targetAmountController.dispose();
    _autoTransferAmountController.dispose();
    super.dispose();
  }

  Future<void> _saveSavingsGoal() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a due date')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      Map<String, dynamic>? autoTransfer;
      if (_autoTransferEnabled) {
        autoTransfer = {
          'enabled': true,
          'amount': double.parse(_autoTransferAmountController.text),
          'frequency': _autoTransferFrequency,
          'nextRun': _savingsService.calculateNextRunDate(_autoTransferFrequency),
        };
      }

      if (widget.goalId != null) {
        // Update existing goal
        await _savingsService.updateSavingsGoal(
          goalId: widget.goalId!,
          goalName: _goalNameController.text,
          targetAmount: double.parse(_targetAmountController.text),
          dueDate: _dueDate!,
          autoTransfer: autoTransfer,
        );
      } else {
        // Create new goal
        await _savingsService.addSavingsGoal(
          goalName: _goalNameController.text,
          targetAmount: double.parse(_targetAmountController.text),
          dueDate: _dueDate!,
          autoTransfer: autoTransfer,
        );
      }
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving goal: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365 * 5)),
    );
    if (picked != null && picked != _dueDate) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Color(0xFF1B4242)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.goalId != null ? 'Edit Savings Goal' : 'Add Savings Goal',
          style: TextStyle(
            color: Color(0xFF1B4242),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _goalNameController,
              decoration: InputDecoration(
                labelText: 'Goal Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a goal name';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _targetAmountController,
              decoration: InputDecoration(
                labelText: 'Target Amount',
                prefixText: '\$',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a target amount';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            InkWell(
              onTap: _selectDate,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Due Date',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _dueDate != null
                      ? '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
                      : 'Select a date',
                  style: TextStyle(
                    color: _dueDate != null ? Colors.black : Colors.grey,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            SwitchListTile(
              title: Text(
                'Enable Auto-Transfer',
                style: TextStyle(
                  color: Color(0xFF1B4242),
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'Automatically transfer contribution amount on schedule',
                style: TextStyle(color: Colors.grey[600]),
              ),
              value: _autoTransferEnabled,
              onChanged: (value) {
                setState(() {
                  _autoTransferEnabled = value;
                });
              },
              activeColor: Color(0xFF1B4242),
            ),
            if (_autoTransferEnabled) ...[
              SizedBox(height: 16),
              TextFormField(
                controller: _autoTransferAmountController,
                decoration: InputDecoration(
                  labelText: 'Auto-Transfer Amount',
                  prefixText: '\$',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (_autoTransferEnabled && (value == null || value.isEmpty)) {
                    return 'Please enter an auto-transfer amount';
                  }
                  if (value != null && value.isNotEmpty && double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _autoTransferFrequency,
                decoration: InputDecoration(
                  labelText: 'Auto-Transfer Frequency',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _frequencies.map((String frequency) {
                  return DropdownMenuItem<String>(
                    value: frequency,
                    child: Text(frequency.capitalize()),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _autoTransferFrequency = newValue;
                    });
                  }
                },
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveSavingsGoal,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF1B4242),
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    widget.goalId != null ? 'Update Goal' : 'Create Goal',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
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