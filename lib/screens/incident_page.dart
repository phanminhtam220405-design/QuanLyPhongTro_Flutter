import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/common_widgets.dart';

class IncidentScreen extends StatefulWidget {
  const IncidentScreen({super.key});
  @override
  State<IncidentScreen> createState() => _IncidentScreenState();
}

class _IncidentScreenState extends State<IncidentScreen> {
  final uid = FirebaseAuth.instance.currentUser!.uid;

  Color _getStatusColor(String status) {
    if (status == 'Mới tiếp nhận') return Colors.blue;
    if (status == 'Đang xử lý') return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text("Sự cố & Bảo trì", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('incidents')
            .where('userId', isEqualTo: uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          var docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text("Chưa có sự cố nào được ghi nhận."));

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: docs.length,
            itemBuilder: (context, index) => _buildIncidentCard(context, docs[index]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1976D2),
        onPressed: () => _showAddIncidentForm(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildIncidentCard(BuildContext context, DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    String status = data['status'] ?? 'Mới tiếp nhận';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            decoration: BoxDecoration(
              color: _getStatusColor(status).withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(data['house'] ?? 'Khu trọ', style: TextStyle(color: _getStatusColor(status), fontWeight: FontWeight.bold, fontSize: 12)),
                Text(data['date'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['title'] ?? 'Sự cố', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: _getStatusColor(status), borderRadius: BorderRadius.circular(20)),
                  child: Text(status, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const Divider(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showDetailDialog(context, data),
                        icon: const Icon(Icons.visibility_outlined, size: 18),
                        label: const Text("XEM"),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (status != 'Đã hoàn thành')
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _updateStatusDialog(context, doc),
                          icon: const Icon(Icons.build_outlined, size: 18),
                          label: const Text("XỬ LÝ"),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        ),
                      ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  void _showAddIncidentForm(BuildContext context) {
    final t = TextEditingController(), d = TextEditingController(), h = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        decoration: const BoxDecoration(color: Color(0xFFF5F5F5), borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Báo sự cố mới", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
            const SizedBox(height: 20),
            whiteInput("Tên khu trọ/Phòng *", "Ví dụ: Nhà Quận 3 - P101", h),
            const SizedBox(height: 15),
            whiteInput("Vấn đề gặp phải *", "Ví dụ: Hư vòi sen", t),
            const SizedBox(height: 15),
            whiteInput("Mô tả chi tiết", "Ví dụ: Nước chảy yếu...", d),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1976D2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () {
                  FirebaseFirestore.instance.collection('incidents').add({
                    'userId': uid, 'title': t.text, 'description': d.text, 'house': h.text, 'status': 'Mới tiếp nhận', 'date': DateTime.now().toString().split(' ')[0]
                  });
                  Navigator.pop(context);
                },
                child: const Text("GỬI YÊU CẦU", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _updateStatusDialog(BuildContext context, DocumentSnapshot doc) {
    final cost = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hoàn thành sửa chữa"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Hãy nhập chi phí sửa chữa để hệ thống lưu vào mục Quản lý chi.", style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 15),
            TextField(controller: cost, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Số tiền (đ)", border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () async {
              await doc.reference.update({'status': 'Đã hoàn thành'});
              await FirebaseFirestore.instance.collection('expenses').add({
                'userId': uid,
                'reason': "Sửa chữa: ${doc['title']}",
                'amount': cost.text,
                'date': DateTime.now(),
                'house': doc['house'],
              });
              Navigator.pop(context);
            },
            child: const Text("XÁC NHẬN XONG"),
          )
        ],
      ),
    );
  }

  void _showDetailDialog(BuildContext context, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(25),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Chi tiết sự cố", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(),
            _infoRow("Vị trí:", data['house'] ?? ''),
            _infoRow("Vấn đề:", data['title'] ?? ''),
            _infoRow("Chi tiết:", data['description'] ?? 'Không có mô tả'),
            const SizedBox(height: 20),
            Center(child: ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("ĐÓNG"))),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String l, String v) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(children: [Text("$l ", style: const TextStyle(fontWeight: FontWeight.bold)), Text(v)]));
  }
}