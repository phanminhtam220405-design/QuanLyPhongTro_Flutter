import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class BillHistoryPage extends StatelessWidget {
  const BillHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Lịch Sử Hóa Đơn"),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bills')
            .where('userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return const Center(child: Text("Lỗi tải dữ liệu"));

          var docs = snapshot.data!.docs;
          if (docs.isEmpty)
            return const Center(child: Text("Không có dữ liệu hóa đơn"));

          docs.sort((a, b) {
            var t1 = a.get('createdAt') as Timestamp?;
            var t2 = b.get('createdAt') as Timestamp?;
            return (t2 ?? Timestamp.now()).compareTo(t1 ?? Timestamp.now());
          });

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var bill = docs[index].data() as Map<String, dynamic>;
              String status = bill['status'] ?? "Đã báo";
              List history = bill['history'] ?? [];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ExpansionTile(
                  leading: Icon(
                    status == "Đã đóng" ? Icons.check_circle : Icons.receipt,
                    color: status == "Đã đóng" ? Colors.green : Colors.orange,
                  ),
                  title: Text(
                    "Tháng ${bill['month']}/${bill['year']}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "Tổng tiền: ${NumberFormat('#,###').format(bill['totalAmount'])}đ",
                  ),
                  trailing: Text(
                    status,
                    style: TextStyle(
                      color: status == "Đã đóng" ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(15),
                      width: double.infinity,
                      color: Colors.grey.shade50,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Chi tiết đóng tiền:",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.blueGrey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (history.isEmpty)
                            const Text(
                              "Chưa có lịch sử giao dịch",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            )
                          else
                            ...history
                                .map(
                                  (h) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      "• ${h['msg']}",
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                )
                                .toList(),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
