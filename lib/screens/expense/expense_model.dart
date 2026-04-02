import 'package:flutter/material.dart';

// Model dữ liệu cho một khoản chi tiêu
class ExpenseCategory {
  final IconData icon;
  final String name;
  final Color color;

  ExpenseCategory({
    required this.icon,
    required this.name,
    required this.color,
  });

  Map<String, dynamic> toMap() => {
    'icon': icon,
    'name': name,
    'color': color,
  };
}

class ExpenseData {
  final String house;
  final String date;
  final String amount;
  final String reason;
  final Map<String, dynamic> category;

  ExpenseData({
    required this.house,
    required this.date,
    required this.amount,
    required this.reason,
    required this.category,
  });

  Map<String, dynamic> toMap() => {
    'house': house,
    'date': date,
    'amount': amount,
    'reason': reason,
    'category': category,
  };
}

class ExpenseCategories {
  static List<Map<String, dynamic>> getDefaults() => [
    {'icon': Icons.water_drop, 'name': 'Tiền nước', 'color': Colors.blue},
    {'icon': Icons.bolt, 'name': 'Tiền điện', 'color': Colors.orange},
    {'icon': Icons.wifi, 'name': 'Internet', 'color': Colors.purple},
    {'icon': Icons.home, 'name': 'Tiền nhà', 'color': Colors.green},
    {'icon': Icons.build, 'name': 'Sửa chữa', 'color': Colors.brown},
    {'icon': Icons.more_horiz, 'name': 'Khác', 'color': Colors.teal},
  ];

  static List<Map<String, dynamic>> getSampleExpenses(List<Map<String, dynamic>> categories) => [
    {
      'house': '123 Nguyễn Đình Chiểu, P5, Q3',
      'date': '01/03/2026',
      'amount': '500000',
      'reason': 'Sửa chữa ống nước',
      'category': categories[4],
    },
    {
      'house': '123 Nguyễn Đình Chiểu, P5, Q3',
      'date': '05/03/2026',
      'amount': '1200000',
      'reason': 'Mua thiết bị điện',
      'category': categories[1],
    },
    {
      'house': '456 Lê Văn Sỹ, P13, Q3',
      'date': '03/03/2026',
      'amount': '300000',
      'reason': 'Vệ sinh định kỳ',
      'category': categories[5],
    },
  ];
}
