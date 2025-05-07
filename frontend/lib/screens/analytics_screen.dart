import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class AnalyticsScreen extends StatefulWidget {
  @override
  _AnalyticsScreenState createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final List<SpendingCategory> categories = [
    SpendingCategory('Rent', 1200, Colors.blue),
    SpendingCategory('Food', 450, Colors.red),
    SpendingCategory('Shopping', 300, Colors.amber),
    SpendingCategory('Transport', 150, Colors.green),
    SpendingCategory('Entertainment', 200, Colors.purple),
  ];

  double get totalSpending =>
      categories.fold(0, (sum, category) => sum + category.amount);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Spending Analysis',
          style: TextStyle(
            color: Color(0xFF1B4242),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildMonthSelector(),
            _buildSpendingOverview(),
            _buildPieChart(),
            _buildCategoryList(),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left),
            onPressed: () {
              // TODO: Implement previous month
            },
          ),
          Text(
            'March 2024',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B4242),
            ),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right),
            onPressed: () {
              // TODO: Implement next month
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingOverview() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF1B4242),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            'Total Spending',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '\$${totalSpending.toStringAsFixed(2)}',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSpendingComparison('vs Last Month', '+12.5%', Colors.red),
              _buildSpendingComparison('vs Budget', '-5.2%', Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingComparison(
      String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPieChart() {
    return Container(
      height: 200,
      padding: EdgeInsets.all(16),
      child: PieChart(
        PieChartData(
          sections: categories
              .map(
                (category) => PieChartSectionData(
                  color: category.color,
                  value: category.amount,
                  title:
                      '${((category.amount / totalSpending) * 100).toStringAsFixed(1)}%',
                  radius: 100,
                  titleStyle: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              )
              .toList(),
          sectionsSpace: 2,
          centerSpaceRadius: 40,
        ),
      ),
    );
  }

  Widget _buildCategoryList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final percentage = (category.amount / totalSpending) * 100;

        return ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: category.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.category,
              color: category.color,
            ),
          ),
          title: Text(
            category.name,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF1B4242),
            ),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${category.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B4242),
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class SpendingCategory {
  final String name;
  final double amount;
  final Color color;

  SpendingCategory(this.name, this.amount, this.color);
}
