import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

Future<List<Map<String, dynamic>>> loadMockTransactions() async {
  final String response = await rootBundle.loadString(
    'assets/mock/mock_transactions.json',
  );
  final data = await json.decode(response) as List;
  return data.map((item) => Map<String, dynamic>.from(item)).toList();
}
