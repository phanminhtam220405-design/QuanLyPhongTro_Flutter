import 'package:flutter/material.dart';

// Utility class cho các chức năng liên quan đến chi tiêu
class ExpenseUtils {
  static String getCurrentDate() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
  }

  static String formatCurrency(String amount) {
    try {
      final number = int.parse(amount.replaceAll(RegExp(r'[^0-9]'), ''));
      return '${number.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]}.',
      )} đ';
    } catch (e) {
      return '0 đ';
    }
  }

  static String calculateTotal(List<Map<String, dynamic>> expenses) {
    int total = 0;
    for (var expense in expenses) {
      total += int.tryParse(expense['amount'].toString()) ?? 0;
    }
    return formatCurrency(total.toString());
  }

  static List<Map<String, dynamic>> filterExpensesByHouse(
    List<Map<String, dynamic>> expenses,
    String selectedHouse,
  ) {
    if (selectedHouse == "Chọn căn nhà" || selectedHouse == "Tất cả các nhà") {
      return expenses;
    }
    return expenses.where((expense) => expense['house'] == selectedHouse).toList();
  }

  static Widget fakeDropdown(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const Icon(Icons.arrow_drop_down),
        ],
      ),
    );
  }
}
