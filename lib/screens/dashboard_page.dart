import 'package:flutter/material.dart';
import 'house_list_page.dart';
import 'expense_page.dart';
import 'report_page.dart';
import 'fee_entry_page.dart';
import 'backup_restore_page.dart';
import 'contact_page.dart';
import 'incident_page.dart';

class MainDashboard extends StatelessWidget {
  const MainDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1976D2),
        title: const Row(
          children: [
            Icon(Icons.home_work, color: Colors.white),
            SizedBox(width: 10),
            Text(
              "QUẢN LÝ TRỌ",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: GridView.count(
              padding: const EdgeInsets.all(20),
              crossAxisCount: 3,
              crossAxisSpacing: 15,
              mainAxisSpacing: 25,
              children: [
                _menuItem(
                  context,
                  Icons.home,
                  "Quản lý nhà,\nphòng, hợp đồng",
                  const HouseListScreen(),
                ),
                _menuItem(
                  context,
                  Icons.grid_view,
                  "Báo phí",
                  const FeeEntryScreen(),
                ),
                _menuItem(
                  context,
                  Icons.calculate,
                  "Quản lý chi",
                  const ExpenseScreen(),
                ),
                _menuItem(
                  context,
                  Icons.bar_chart,
                  "Báo cáo",
                  const ReportScreen(),
                ),
                _menuItem(
                  context,
                  Icons.car_repair,
                  "Quản lý sự cố",
                  const IncidentScreen(),
                ),
                _menuItem(
                  context,
                  Icons.sync,
                  "Sao lưu, phục\nhồi dữ liệu",
                  const BackupRestoreScreen(),
                ),
                _menuItem(
                  context,
                  Icons.undo,
                  "Liên hệ, góp ý",
                  const ContactScreen(),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 20),
            child: Text(
              "Phiên bản 2.5.3",
              style: TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuItem(
    BuildContext context,
    IconData icon,
    String title,
    Widget? page,
  ) {
    return GestureDetector(
      onTap: () => page != null
          ? Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => page),
            )
          : null,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF42A5F5),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
