import 'package:flutter/material.dart';
import '../widgets/common_widgets.dart';

class FeeEntryScreen extends StatelessWidget {
  const FeeEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1976D2),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Lập hóa đơn / Báo phí",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            fakeDropdown("Chọn căn nhà"),
            const SizedBox(height: 10),
            fakeDropdown("Chọn phòng (Tất cả)"),
            const SizedBox(height: 20),
            const Text(
              "Chỉ số Điện (Kwh)",
              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1976D2)),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: fakeInput("Chỉ số cũ", "1.250")),
                const SizedBox(width: 10),
                Expanded(child: fakeInput("Chỉ số mới", "0")),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              "Chỉ số Nước (Khối)",
              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1976D2)),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: fakeInput("Chỉ số cũ", "450")),
                const SizedBox(width: 10),
                Expanded(child: fakeInput("Chỉ số mới", "0")),
              ],
            ),
            const SizedBox(height: 20),
            fakeInput("Phí dịch vụ khác / Ghi chú", "Nhập nội dung..."),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {},
                child: const Text("TÍNH TIỀN & XUẤT HÓA ĐƠN", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 15),
            Center(
              child: TextButton(
                onPressed: () {},
                child: const Text(
                  "Xem Thống kê báo phí / Lịch sử",
                  style: TextStyle(color: Color(0xFF1976D2), fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}