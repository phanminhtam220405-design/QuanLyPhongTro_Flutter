import 'package:flutter/material.dart';
import 'login_page.dart';
import 'register_page.dart';
import 'screens/dashboard_page.dart';

void main() {
  runApp(const QuanLyTroApp());
}

class QuanLyTroApp extends StatelessWidget {
  const QuanLyTroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quản Lý Trọ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF1976D2),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1976D2)),
        useMaterial3: true,
      ),
      home: LoginPage(),
      routes: {
        '/login': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
        '/dashboard': (context) => const MainDashboard(),
      },
    );
  }
}