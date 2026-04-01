import 'package:flutter/material.dart';

class IncidentScreen extends StatefulWidget {
  const IncidentScreen({super.key});

  @override
  State<IncidentScreen> createState() => _IncidentScreenState();
}

class _IncidentScreenState extends State<IncidentScreen> {
  // Dữ liệu mẫu cho sự cố
  List<Map<String, dynamic>> incidents = [
    {
      'id': '1',
      'house': '123 Nguyễn Đình Chiểu, P5, Q3',
      'title': 'Hư vòi sen phòng 202',
      'description': 'Nước chảy yếu và bị rỉ ở khớp nối',
      'status': 'Mới tiếp nhận',
      'date': '01/04/2026',
      'priority': 'Cao',
    },
    {
      'id': '2',
      'house': '456 Lê Văn Sỹ, P13, Q3',
      'title': 'Hỏng ổ cắm điện',
      'description': 'Ổ cắm bếp bị khét khi cắm nồi cơm',
      'status': 'Đang xử lý',
      'date': '31/03/2026',
      'priority': 'Khẩn cấp',
    },
  ];

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Mới tiếp nhận':
        return Colors.blue;
      case 'Đang xử lý':
        return Colors.orange;
      case 'Đã hoàn thành':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // Hàm xử lý khi hoàn thành sự cố (Kết nối với Quản lý chi)
  void _completeIncident(int index) {
    final TextEditingController costController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hoàn thành bảo trì'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Nhập chi phí sửa chữa cho: ${incidents[index]['title']}'),
            const SizedBox(height: 10),
            TextField(
              controller: costController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Số tiền (VNĐ)',
                border: OutlineInputBorder(),
                suffixText: 'đ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                incidents[index]['status'] = 'Đã hoàn thành';
                // Ở đây sau này bạn sẽ gọi hàm callback hoặc Provider
                // để insert một bản ghi vào List expenses của bạn.
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã cập nhật trạng thái và lưu chi phí!'),
                ),
              );
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1976D2),
        title: const Text(
          "Quản lý sự cố & Bảo trì",
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: incidents.length,
        itemBuilder: (context, index) {
          final item = incidents[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: _getStatusColor(
                  item['status'],
                ).withOpacity(0.2),
                child: Icon(
                  Icons.build,
                  color: _getStatusColor(item['status']),
                ),
              ),
              title: Text(
                item['title'],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('${item['house']}\nNgày: ${item['date']}'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(item['status']),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item['status'],
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Chi tiết sự cố:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(item['description']),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (item['status'] != 'Đã hoàn thành')
                            OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  item['status'] = 'Đang xử lý';
                                });
                              },
                              child: const Text("Sửa chữa"),
                            ),
                          const SizedBox(width: 8),
                          if (item['status'] != 'Đã hoàn thành')
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              onPressed: () => _completeIncident(index),
                              child: const Text(
                                "Hoàn thành",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1976D2),
        onPressed: () {
          // Logic thêm sự cố mới từ chủ trọ/khách trọ
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
