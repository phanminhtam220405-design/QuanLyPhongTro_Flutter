import 'package:flutter/material.dart';

class BackupRestoreScreen extends StatelessWidget {
  const BackupRestoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1976D2),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Sao lưu & Phục hồi", style: TextStyle(color: Colors.white, fontSize: 18)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("SAO LƯU DỮ LIỆU", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1976D2))),
            const SizedBox(height: 10),
            _backupCard(Icons.cloud_upload, "Sao lưu lên Google Drive", "An toàn, tự động đồng bộ qua email", Colors.blue),
            _backupCard(Icons.storage, "Lưu vào bộ nhớ máy", "Tạo file backup nội bộ trên điện thoại", Colors.blueGrey),
            const SizedBox(height: 30),
            const Text("PHỤC HỒI DỮ LIỆU", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red)),
            const SizedBox(height: 10),
            _backupCard(Icons.settings_backup_restore, "Phục hồi từ Cloud", "Lấy lại dữ liệu từ Google Drive", Colors.orange),
            _backupCard(Icons.file_present, "Chọn file từ máy", "Chọn file backup có sẵn trong máy", Colors.green),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info, color: Colors.grey),
                  SizedBox(width: 10),
                  Expanded(child: Text("Lần sao lưu cuối cùng: 08:45 - 08/03/2026", style: TextStyle(color: Colors.black54, fontSize: 13))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _backupCard(IconData icon, String title, String sub, Color color) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(sub, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {},
      ),
    );
  }
}