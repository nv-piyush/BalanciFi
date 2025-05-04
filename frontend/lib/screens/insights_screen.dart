import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/expense_service.dart';
import '../services/budget_service.dart';

class InsightsScreen extends StatefulWidget {
  @override
  _InsightsScreenState createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> with SingleTickerProviderStateMixin {
  final ExpenseService _expenseService = ExpenseService();
  final BudgetService _budgetService = BudgetService();
  DateTime _selectedDate = DateTime.now();
  late AnimationController _animationController;
  late Animation<double> _animation;
  Map<String, double> _budgetLimits = {};
  Map<String, double> _budgetSpent = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOutCubic,
      ),
    );
    _animationController.forward();
    _loadBudgets();
  }

  Future<void> _loadBudgets() async {
    final budgets = await _budgetService.getBudgets();
    setState(() {
      _budgetLimits = {
        for (var budget in budgets)
          budget['category'] as String: (budget['limit'] as num).toDouble()
      };
      _budgetSpent = {
        for (var budget in budgets)
          budget['category'] as String: (budget['spent'] as num).toDouble()
      };
    });
  }

  String _getBudgetWarningMessage() {
    final messages = [
      "Uh-oh, your budget wandered off!",
      "Your budget took a little nap this month!",
      "Your piggy bank's feeling a bit dizzy!",
      "Budget went oopsie! Next month's a reset."
    ];
    return messages[DateTime.now().millisecondsSinceEpoch % messages.length];
  }

  bool _isOverBudget(String category, double amount) {
    final limit = _budgetLimits[category];
    final spent = _budgetSpent[category];
    if (limit == null || spent == null) return false;
    return spent > limit;
  }

  // You can customize this mapping for icons/colors per category
  final Map<String, IconData> categoryIcons = {
    'Rent': Icons.home,
    'Food': Icons.restaurant,
    'Food Delivery': Icons.storefront,
    'Groceries': Icons.lunch_dining,
    'Cleaning': Icons.cleaning_services,
    'Transport': Icons.directions_car,
    'Transportation': Icons.directions_car,
    'Entertainment': Icons.movie,
    'Shopping': Icons.shopping_bag,
    'Utilities': Icons.power,
    'Health': Icons.health_and_safety,
    'Other': Icons.category,
  };

  final List<Color> chartColors = [
    Color(0xFFB5EAD7), // Mint
    Color(0xFFC7CEEA), // Lavender
    Color(0xFFFFDAC1), // Peach
    Color(0xFFFFB7B2), // Coral
    Color(0xFFE2F0CB), // Sage
    Color(0xFFFF9AA2), // Pink
    Color(0xFFFFB7B2), // Light Coral
    Color(0xFFD4A5A5), // Dusty Rose
    Color(0xFFB5EAD7).withOpacity(0.8), // Mint with opacity
    Color(0xFFC7CEEA).withOpacity(0.8), // Lavender with opacity
  ];

  DateTime get _startOfMonth => DateTime(_selectedDate.year, _selectedDate.month, 1);
  DateTime get _endOfMonth => DateTime(_selectedDate.year, _selectedDate.month + 1, 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Spend Analyzer',
          style: TextStyle(
            color: Color(0xFF1B4242),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today, color: Color(0xFF1B4242)),
            onPressed: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null && picked != _selectedDate) {
                setState(() {
                  _selectedDate = picked;
                  _animationController.reset();
                  _animationController.forward();
                });
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _expenseService.getExpenses(
          startDate: _startOfMonth,
          endDate: _endOfMonth,
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error loading expenses'));
          }
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          final expenses = snapshot.data!.docs;
          if (expenses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.pie_chart_outline,
                    size: 64,
                    color: Color(0xFF1B4242).withOpacity(0.5),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No expenses for this month',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          // Group and sum by category
          Map<String, double> categoryTotals = {};
          for (var doc in expenses) {
            final data = doc.data() as Map<String, dynamic>;
            final category = (data['category'] ?? 'Other').toString();
            final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
            categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
          }
          final totalExpenditure = categoryTotals.values.fold(0.0, (a, b) => a + b);

          // Sort categories by amount (descending)
          final sortedCategories = categoryTotals.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          // Assign a color to each category
          final Map<String, Color> categoryColors = {
            for (int i = 0; i < sortedCategories.length; i++)
              sortedCategories[i].key: chartColors[i % chartColors.length]
          };

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.calendar_today, size: 20, color: Color(0xFF1B4242)),
                              SizedBox(width: 8),
                              Text(
                                '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                  color: Color(0xFF1B4242),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          AnimatedBuilder(
                            animation: _animation,
                            builder: (context, child) {
                              return Center(
                                child: SizedBox(
                                  height: 300,
                                  width: 300,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      PieChart(
                                        PieChartData(
                                          sections: sortedCategories.map((entry) {
                                            final color = categoryColors[entry.key]!;
                                            return PieChartSectionData(
                                              color: color,
                                              value: entry.value,
                                              title: '',
                                              radius: 30,
                                            );
                                          }).toList(),
                                          centerSpaceRadius: 80,
                                          sectionsSpace: 3,
                                          startDegreeOffset: 270,
                                        ),
                                      ),
                                      Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Total Spendz for\n${_getMonthYear()}',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.grey[700],
                                              fontSize: 14,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            '₹${totalExpenditure.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              color: Color(0xFF1B4242),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 24,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          SizedBox(height: 16),
                          // Legend Section
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: sortedCategories.map((entry) {
                              final color = categoryColors[entry.key]!;
                              return Container(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: color),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      entry.key,
                                      style: TextStyle(
                                        color: Color(0xFF1B4242),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Category Breakdown',
                    style: TextStyle(
                      color: Color(0xFF1B4242),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 8),
                  ...sortedCategories.map((entry) => _CategoryCard(
                        name: entry.key,
                        amount: entry.value,
                        color: categoryColors[entry.key]!,
                        icon: categoryIcons[entry.key] ?? Icons.category,
                        percentage: (entry.value / totalExpenditure * 100).toStringAsFixed(1),
                        isOverBudget: _isOverBudget(entry.key, entry.value),
                      )),
                  SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _getMonthYear() {
    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${monthNames[_selectedDate.month - 1]} ${_selectedDate.year}';
  }
}

class _CategoryCard extends StatelessWidget {
  final String name;
  final double amount;
  final Color color;
  final IconData icon;
  final String percentage;
  final bool isOverBudget;

  const _CategoryCard({
    required this.name,
    required this.amount,
    required this.color,
    required this.icon,
    required this.percentage,
    required this.isOverBudget,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          border: isOverBudget
              ? Border.all(color: Colors.red.withOpacity(0.5), width: 2)
              : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            color: Color(0xFF1B4242),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '$percentage% of total',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        if (isOverBudget)
                          Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text(
                              "Uh-oh, your budget wandered off!",
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    '₹${amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Color(0xFF1B4242),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

