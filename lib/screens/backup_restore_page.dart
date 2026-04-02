import 'package:flutter/material.dart';

class BackupRestoreScreen extends StatelessWidget {
  const BackupRestoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(backgroundColor: const Color(0xFF1976D2), foregroundColor: Colors.white, title: const Text("Sao lưu & Bảo mật")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.verified_user, size: 80, color: Colors.green),
            const SizedBox(height: 20),
            const Text("DỮ LIỆU ĐÃ ĐƯỢC BẢO VỆ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            const Text("Mọi thông tin nhà trọ của bạn đều được tự động đồng bộ hóa với hệ thống Cloud Firebase theo thời gian thực.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 30),
            _infoCard("Lần đồng bộ cuối", "Vừa xong", Icons.access_time),
            _infoCard("Trạng thái", "An toàn (100%)", Icons.check_circle_outline),
            const Spacer(),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1976D2)),
                onPressed: () {}, 
                icon: const Icon(Icons.sync, color: Colors.white), 
                label: const Text("KIỂM TRA ĐỒNG BỘ", style: TextStyle(color: Colors.white))
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _infoCard(String t, String v, IconData i) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(i, color: Colors.blue),
        title: Text(t, style: const TextStyle(fontSize: 14)),
        trailing: Text(v, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
      ),
    );
  }
}