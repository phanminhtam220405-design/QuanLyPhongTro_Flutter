import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});
  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  final reason = TextEditingController();
  final amount = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(backgroundColor: const Color(0xFF1976D2), foregroundColor: Colors.white, title: const Text("Quản lý chi phí")),
      body: Column(
        children: [
          // KHU VỰC NHẬP LIỆU TRẮNG BO GÓC
          Padding(
            padding: const EdgeInsets.all(15),
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade300)),
              child: Column(
                children: [
                  TextField(controller: reason, decoration: const InputDecoration(labelText: "Lý do chi", border: InputBorder.none)),
                  const Divider(),
                  TextField(controller: amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Số tiền", border: InputBorder.none)),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1976D2)),
                      onPressed: () {
                        if (reason.text.isEmpty) return;
                        FirebaseFirestore.instance.collection('expenses').add({
                          'userId': uid,
                          'reason': reason.text,
                          'amount': amount.text.replaceAll(RegExp(r'[^0-9]'), ''),
                          'date': FieldValue.serverTimestamp(),
                        });
                        reason.clear(); amount.clear();
                      },
                      child: const Text("LƯU KHOẢN CHI", style: TextStyle(color: Colors.white)),
                    ),
                  )
                ],
              ),
            ),
          ),
          // DANH SÁCH CHI PHÍ
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('expenses').where('userId', isEqualTo: uid).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text("Lỗi tải dữ liệu. Hãy kiểm tra Index."));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                var docs = snapshot.data!.docs;
                if (docs.isEmpty) return const Center(child: Text("Chưa có khoản chi nào."));

                return ListView(
                  children: docs.map((doc) {
                    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                      child: ListTile(
                        leading: const CircleAvatar(backgroundColor: Colors.redAccent, child: Icon(Icons.money_off, color: Colors.white)),
                        title: Text(data['reason'] ?? 'Không tên'),
                        trailing: Text("-${data['amount'] ?? 0} đ", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        onLongPress: () => doc.reference.delete(), // Nhấn giữ để xóa
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}