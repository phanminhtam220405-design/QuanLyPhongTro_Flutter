import 'package:flutter/material.dart';
import 'room_list_page.dart';

class HouseListScreen extends StatelessWidget {
  const HouseListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1976D2),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: const Text("Các căn nhà của bạn", style: TextStyle(color: Colors.white, fontSize: 18)),
        actions: [IconButton(icon: const Icon(Icons.add_circle_outline, color: Colors.white), onPressed: () {})],
      ),
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          Card(
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: Color(0xFF1976D2), width: 1.5),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  color: const Color(0xFF1976D2),
                  child: Row(
                    children: [
                      const Icon(Icons.home, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      const Expanded(child: Text("123 Nguyễn Đình Chiểu, P5, Q3", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                      IconButton(onPressed: () {}, icon: const Icon(Icons.edit, color: Colors.white, size: 20)),
                      IconButton(onPressed: () {}, icon: const Icon(Icons.close, color: Colors.white, size: 20)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Tâm - 0987654321", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 10),
                      _feeRow("Loại phí", "Đơn vị tính", "Giá tiền", isHeader: true),
                      _feeRow("Điện", "KWH", "4.000 đ"),
                      _feeRow("Nước", "phòng", "50.000 đ"),
                      _feeRow("Xe", "chiếc", "10.000 đ"),
                      _feeRow("Internet", "phòng", "100.000 đ"),
                      _feeRow("Giặt sấy", "phòng", "50.000 đ"),
                      _feeRow("Thang máy", "phòng", "0 đ"),
                      _feeRow("Rác", "phòng", "17.000 đ"),
                      _feeRow("Dịch vụ", "phòng", "0 đ"),
                      const SizedBox(height: 10),
                      const Text("Thông tin chuyển khoản", style: TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
                      const Text("Chủ TK: Tâm"),
                      const Text("Ngân hàng Quân Đội - MB Bank"),
                      const Text("STK: 0987654321"),
                      const SizedBox(height: 15),
                      Center(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white),
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RoomListScreen())),
                          child: const Text("Xem danh sách phòng"),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _feeRow(String c1, String c2, String c3, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(c1, style: TextStyle(fontWeight: isHeader ? FontWeight.bold : FontWeight.normal))),
          Expanded(child: Text(c2, textAlign: TextAlign.center, style: TextStyle(fontWeight: isHeader ? FontWeight.bold : FontWeight.normal))),
          Expanded(child: Text(c3, textAlign: TextAlign.right, style: TextStyle(fontWeight: isHeader ? FontWeight.bold : FontWeight.normal))),
        ],
      ),
    );
  }
}