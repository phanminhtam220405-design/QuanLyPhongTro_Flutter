import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'house_list_page.dart';
import 'expense_page.dart';
import 'report_page.dart';
import 'fee_entry_page.dart';
import 'incident_page.dart';
import 'backup_restore_page.dart';
import 'contact_page.dart';

class MainDashboard extends StatelessWidget {
  const MainDashboard({super.key});

  void _showUserMenu(BuildContext context, User? user) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.account_circle,
              size: 60,
              color: Color(0xFF1976D2),
            ),
            const SizedBox(height: 10),
            Text(
              user?.email ?? "Chủ trọ Admin",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Text(
              "Hệ thống quản lý chuyên nghiệp",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 20),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                "ĐĂNG XUẤT",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) Navigator.pop(context); // Đóng menu
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2), // Nền xám nhạt sang trọng
      appBar: AppBar(
        backgroundColor: const Color(0xFF1976D2),
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text(
          "QUẢN LÝ TRỌ HUIT",
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          InkWell(
            onTap: () => _showUserMenu(context, user),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(25),
              decoration: const BoxDecoration(
                color: Color(0xFF1976D2),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(35),
                ),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.person, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Xin chào chủ nhà,",
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        Text(
                          user?.displayName ?? "ADMIN",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down, color: Colors.white70),
                ],
              ),
            ),
          ),

          Expanded(
            child: GridView.count(
              padding: const EdgeInsets.all(20),
              crossAxisCount: 3, // 3 cột cực đẹp
              crossAxisSpacing: 12,
              mainAxisSpacing: 15,
              children: [
                _buildMenuCard(
                  context,
                  "Nhà & Phòng",
                  Icons.home_work,
                  Colors.blue,
                  const HouseListScreen(),
                ),
                _buildMenuCard(
                  context,
                  "Báo phí",
                  Icons.receipt_long,
                  Colors.purple,
                  const FeeEntryScreen(),
                ),
                _buildMenuCard(
                  context,
                  "Quản lý chi",
                  Icons.account_balance_wallet,
                  Colors.redAccent,
                  const ExpenseScreen(),
                ),
                _buildMenuCard(
                  context,
                  "Sự cố",
                  Icons.build_circle_outlined,
                  Colors.deepOrange,
                  const IncidentScreen(),
                ),
                _buildMenuCard(
                  context,
                  "Báo cáo",
                  Icons.bar_chart,
                  Colors.orange,
                  const ReportScreen(),
                ),
                _buildMenuCard(
                  context,
                  "Sao lưu",
                  Icons.cloud_sync,
                  Colors.green,
                  const BackupRestoreScreen(),
                ),
                _buildMenuCard(
                  context,
                  "Góp ý",
                  Icons.feedback_outlined,
                  Colors.teal,
                  const ContactScreen(),
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.only(bottom: 20),
            child: Text(
              "Phiên bản 3.5.0 - Cloud Synchronized",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    Widget page,
  ) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => page),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon nằm trong vòng tròn màu mờ
            CircleAvatar(
              radius: 25,
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 10,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
