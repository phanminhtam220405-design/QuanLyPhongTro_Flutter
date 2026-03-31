import 'package:flutter/material.dart';
import '../widgets/common_widgets.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1976D2),
        title: const Text("Báo cáo", style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(10),
            child: Text("Chọn căn nhà để xem báo cáo", style: TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: fakeDropdown("Chọn căn nhà"),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _tabBtn("3 tháng", true),
              _tabBtn("6 tháng", false),
              _tabBtn("12 tháng", false),
              _tabBtn("Tùy chọn", false),
            ],
          ),
          const SizedBox(height: 20),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text("THU", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
              Text("CHI", style: TextStyle(fontWeight: FontWeight.bold)),
              Text("LỢI NHUẬN", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const Expanded(child: EmptyDataWidget()),
        ],
      ),
    );
  }

  Widget _tabBtn(String label, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF1976D2) : Colors.white,
        border: Border.all(color: const Color(0xFF1976D2)),
      ),
      child: Text(
        label,
        style: TextStyle(color: active ? Colors.white : const Color(0xFF1976D2), fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}