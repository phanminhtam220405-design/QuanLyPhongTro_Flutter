import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../house_list_page.dart';
import '../expense/expense_page.dart';
import '../report_page.dart';
import '../fee_entry_page.dart';
import '../backup_restore_page.dart';
import '../contact_page.dart';
import '../notifications/admin_send_notification.dart';
import '../incidents/admin_incident_page.dart';

class MainDashboard extends StatelessWidget {
  const MainDashboard({super.key});

  void _showUserMenu(BuildContext context, User? user) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 35,
              backgroundColor: Color(0xFFE3F2FD),
              child: Icon(Icons.person, size: 40, color: Color(0xFF1976D2)),
            ),
            const SizedBox(height: 15),

            Text(
              user?.email ?? "admin@gmail.com",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),

            const SizedBox(height: 5),

            const Text(
              "Hệ thống quản lý phòng trọ",
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 20),

            const Divider(),

            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                "Đăng xuất",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () async {
                await FirebaseAuth.instance.signOut();

                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          "Quản lý phòng trọ",
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active),
            tooltip: 'Gửi thông báo',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminSendNotificationPage(),
                ),
              );
            },
          ),
        ],
      ),

      body: Column(
        children: [
          // HEADER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(25),
            decoration: const BoxDecoration(
              color: Color(0xFF1976D2),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(35)),
            ),
            child: InkWell(
              onTap: () => _showUserMenu(context, user),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.person, color: Colors.white, size: 35),
                  ),

                  const SizedBox(width: 15),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Xin chào,",
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),

                        Text(
                          user?.displayName ?? "ADMIN",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                ],
              ),
            ),
          ),

          const SizedBox(height: 15),

          // THỐNG KÊ
          const SizedBox(height: 20),

          // MENU
          Expanded(
            child: GridView.count(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              crossAxisCount: 2,
              childAspectRatio: 1.1,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              children: [
                _buildMenuCard(
                  context,
                  "Nhà & Phòng",
                  "Quản lý phòng trọ",
                  Icons.home_work,
                  Colors.blue,
                  const HouseListScreen(),
                ),

                _buildMenuCard(
                  context,
                  "Báo phí",
                  "Tạo hóa đơn",
                  Icons.receipt_long,
                  Colors.purple,
                  const FeeEntryScreen(),
                ),

                _buildMenuCard(
                  context,
                  "Quản lý chi",
                  "Theo dõi chi phí",
                  Icons.account_balance_wallet,
                  Colors.redAccent,
                  const ExpenseScreen(),
                ),

                _buildMenuCard(
                  context,
                  "Sự cố",
                  "Xử lý vấn đề",
                  Icons.build_circle_outlined,
                  Colors.deepOrange,
                  const AdminIncidentPage(),
                ),

                _buildMenuCard(
                  context,
                  "Thông báo",
                  "Gửi thông báo",
                  Icons.notifications_active,
                  Colors.amber,
                  const AdminSendNotificationPage(),
                ),

                _buildMenuCard(
                  context,
                  "Báo cáo",
                  "Thống kê dữ liệu",
                  Icons.bar_chart,
                  Colors.orange,
                  const ReportScreen(),
                ),

                _buildMenuCard(
                  context,
                  "Sao lưu",
                  "Backup dữ liệu",
                  Icons.cloud_sync,
                  Colors.green,
                  const BackupRestoreScreen(),
                ),

                _buildMenuCard(
                  context,
                  "Góp ý",
                  "Liên hệ hỗ trợ",
                  Icons.feedback_outlined,
                  Colors.teal,
                  const ContactScreen(),
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.only(bottom: 15),
            child: Text(
              "Version 3.5.0 - Firebase Cloud",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(icon, color: color),
          ),

          const SizedBox(height: 10),

          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: color,
            ),
          ),

          const SizedBox(height: 5),

          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    Widget page,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => page));
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, color: color, size: 28),
            ),

            const Spacer(),

            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),

            const SizedBox(height: 5),

            Text(
              subtitle,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
