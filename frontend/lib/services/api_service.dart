import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000';  // Update with your deployed backend URL

  static Future<List<dynamic>> getExpenses(String userId) async {
    final url = Uri.parse('$baseUrl/expenses/$userId');
    final response = await http.get(url);
    if(response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load expenses');
    }
  }

  static Future<void> addExpense(String userId, Map<String, dynamic> expenseData) async {
    final url = Uri.parse('$baseUrl/expenses/$userId');
    final response = await http.post(url, headers: {'Content-Type': 'application/json'}, body: json.encode(expenseData));
    if(response.statusCode != 200) {
      throw Exception('Failed to add expense');
    }
  }

  static Future<List<dynamic>> getBudgets(String userId) async {
    final url = Uri.parse('$baseUrl/budgets/$userId');
    final response = await http.get(url);
    if(response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load budgets');
    }
  }

  static Future<void> addBudget(String userId, Map<String, dynamic> budgetData) async {
    final url = Uri.parse('$baseUrl/budgets/$userId');
    final response = await http.post(url, headers: {'Content-Type': 'application/json'}, body: json.encode(budgetData));
    if(response.statusCode != 200) {
      throw Exception('Failed to add budget');
    }
  }

  static Future<List<dynamic>> getSavings(String userId) async {
    final url = Uri.parse('$baseUrl/savings/$userId');
    final response = await http.get(url);
    if(response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load savings goals');
    }
  }

  static Future<void> addSavings(String userId, Map<String, dynamic> savingsData) async {
    final url = Uri.parse('$baseUrl/savings/$userId');
    final response = await http.post(url, headers: {'Content-Type': 'application/json'}, body: json.encode(savingsData));
    if(response.statusCode != 200) {
      throw Exception('Failed to add savings goal');
    }
  }

  static Future<Map<String, dynamic>> getInsights(String userId) async {
    final url = Uri.parse('$baseUrl/insights/$userId');
    final response = await http.get(url);
    if(response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to get insights');
    }
  }

  static Future<Map<String, dynamic>> getProfile(String userId) async {
    final url = Uri.parse('$baseUrl/profile/$userId');
    final response = await http.get(url);
    if(response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to get profile');
    }
  }

  // Bills API
  static Future<List<dynamic>> getBills(String userId) async {
    final url = Uri.parse('$baseUrl/bills/$userId');
    final response = await http.get(url);
    if(response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load bills');
    }
  }

  static Future<void> addBill(String userId, Map<String, dynamic> billData) async {
    final url = Uri.parse('$baseUrl/bills/$userId');
    final response = await http.post(url, headers: {'Content-Type': 'application/json'}, body: json.encode(billData));
    if(response.statusCode != 200) {
      throw Exception('Failed to add bill');
    }
  }

  // Rewards API
  static Future<List<dynamic>> getRewards(String userId) async {
    final url = Uri.parse('$baseUrl/rewards/$userId');
    final response = await http.get(url);
    if(response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load rewards');
    }
  }

  static Future<void> addReward(String userId, Map<String, dynamic> rewardData) async {
    final url = Uri.parse('$baseUrl/rewards/$userId');
    final response = await http.post(url, headers: {'Content-Type': 'application/json'}, body: json.encode(rewardData));
    if(response.statusCode != 200) {
      throw Exception('Failed to add reward');
    }
  }

  // Receipt scanning: Sends image file to backend.
  static Future<Map<String, dynamic>> scanReceipt(XFile receiptImage) async {
    final url = Uri.parse('$baseUrl/receipt/dummyUserId'); // Replace with actual userId as needed.
    var request = http.MultipartRequest('POST', url);
    request.files.add(await http.MultipartFile.fromPath('receipt', receiptImage.path));
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    if(response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to scan receipt');
    }
  }

  // Currency conversion endpoint.
  static Future<Map<String, dynamic>> convertCurrency(String from, String to, double amount) async {
    final url = Uri.parse('$baseUrl/currency/convert?from=$from&to=$to&amount=$amount');
    final response = await http.get(url);
    if(response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to convert currency');
    }
  }
}
