import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_expense_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> expenses = [];
  bool isLoading = false;
  final user = FirebaseAuth.instance.currentUser;

  // Fetch expenses from Node.js backend.
  Future<void> fetchExpenses() async {
    setState(() {
      isLoading = true;
    });
    // Replace the URL below with your deployed Node.js backend address.
    final url = Uri.parse('http://localhost:3000/expenses/${user!.uid}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          expenses = json.decode(response.body);
        });
      } else {
        print('Failed to load expenses');
      }
    } catch (error) {
      print('Error: $error');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchExpenses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Expense Tracker'),
        actions: [
          IconButton(
              icon: Icon(Icons.logout),
              onPressed: () {
                FirebaseAuth.instance.signOut();
              }
          )
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: expenses.length,
        itemBuilder: (context, index) {
          var expense = expenses[index];
          return ListTile(
            title: Text(expense['title'] ?? 'No Title'),
            subtitle: Text('\$${expense['amount']}'),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Navigate to Add Expense Screen then refresh expenses list.
          await Navigator.push(
              context, MaterialPageRoute(builder: (_) => AddExpenseScreen()));
          fetchExpenses();
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
