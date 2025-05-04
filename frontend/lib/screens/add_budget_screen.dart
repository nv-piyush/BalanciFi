import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/budget_service.dart';

class AddBudgetScreen extends StatefulWidget {
  final String? budgetId;
  final String? initialCategory;
  final double? initialLimit;
  final bool? initialRollover;

  const AddBudgetScreen({
    Key? key,
    this.budgetId,
    this.initialCategory,
    this.initialLimit,
    this.initialRollover,
  }) : super(key: key);

  @override
  _AddBudgetScreenState createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends State<AddBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _categoryController = TextEditingController();
  final _limitController = TextEditingController();
  final _customCategoryController = TextEditingController();
  final _budgetService = BudgetService();
  bool _isLoading = false;
  bool _rollover = false;
  bool _showCustomCategoryField = false;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Food', 'icon': Icons.restaurant},
    {'name': 'Shopping', 'icon': Icons.shopping_bag},
    {'name': 'Transport', 'icon': Icons.directions_car},
    {'name': 'Entertainment', 'icon': Icons.movie},
    {'name': 'Bills', 'icon': Icons.receipt_long},
    {'name': 'Health', 'icon': Icons.health_and_safety},
    {'name': 'Education', 'icon': Icons.school},
    {'name': 'Travel', 'icon': Icons.flight},
    {'name': 'Other', 'icon': Icons.category},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null) {
      _categoryController.text = widget.initialCategory!;
    }
    if (widget.initialLimit != null) {
      _limitController.text = widget.initialLimit!.toString();
    }
    if (widget.initialRollover != null) {
      _rollover = widget.initialRollover!;
    }
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _limitController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  Future<void> _saveBudget() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final category = _showCustomCategoryField 
          ? _customCategoryController.text.trim()
          : _categoryController.text;

      if (widget.budgetId != null) {
        // Update existing budget
        await _budgetService.updateBudget(
          budgetId: widget.budgetId!,
          category: category,
          limit: double.parse(_limitController.text),
          rollover: _rollover,
        );
      } else {
        // Create new budget
        await _budgetService.addBudget(
          category: category,
          limit: double.parse(_limitController.text),
          rollover: _rollover,
        );
      }
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving budget: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
          widget.budgetId != null ? 'Edit Budget' : 'Add Budget',
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
            Text(
              'Category',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((category) {
                bool isSelected = _categoryController.text == category['name'];
                return InkWell(
                  onTap: () {
                    setState(() {
                      _categoryController.text = category['name'];
                      _showCustomCategoryField = category['name'] == 'Other';
                      if (!_showCustomCategoryField) {
                        _customCategoryController.clear();
                      }
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Color(0xFF1B4242)
                          : Color(0xFF1B4242).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          category['icon'],
                          color: isSelected ? Colors.white : Color(0xFF1B4242),
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          category['name'],
                          style: TextStyle(
                            color: isSelected ? Colors.white : Color(0xFF1B4242),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            if (_showCustomCategoryField) ...[
              SizedBox(height: 16),
              TextFormField(
                controller: _customCategoryController,
                decoration: InputDecoration(
                  labelText: 'Custom Category Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a category name';
                  }
                  return null;
                },
              ),
            ],
            SizedBox(height: 16),
            TextFormField(
              controller: _limitController,
              decoration: InputDecoration(
                labelText: 'Limit Amount',
                prefixText: '\$',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an amount';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            SwitchListTile(
              title: Text(
                'Enable Rollover',
                style: TextStyle(
                  color: Color(0xFF1B4242),
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'Unused budget will carry over to next month',
                style: TextStyle(color: Colors.grey[600]),
              ),
              value: _rollover,
              onChanged: (value) {
                setState(() {
                  _rollover = value;
                });
              },
              activeColor: Color(0xFF1B4242),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveBudget,
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
                    widget.budgetId != null ? 'Update Budget' : 'Create Budget',
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