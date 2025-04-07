import 'dart:convert';
import 'package:flutter/services.dart';

Future<Map<String, dynamic>> categorizeTransaction(
  Map<String, dynamic> txn,
) async {
  final String rulesJson = await rootBundle.loadString(
    'assets/categorization/category_rules.json',
  );
  final Map<String, dynamic> rules = json.decode(rulesJson);
  final String merchant = txn["merchant"].toString().toLowerCase();

  for (final category in rules.entries) {
    for (final keyword in category.value) {
      if (merchant.contains(keyword)) {
        txn["category"] = category.key;
        return txn;
      }
    }
  }

  txn["category"] = "Uncategorized";
  return txn;
}
