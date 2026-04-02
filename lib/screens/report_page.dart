import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(backgroundColor: const Color(0xFF1976D2), foregroundColor: Colors.white, title: const Text("Báo cáo tài chính")),
      body: FutureBuilder(
        future: Future.wait([
          FirebaseFirestore.instance.collection('bills').where('userId', isEqualTo: uid).get(),
          FirebaseFirestore.instance.collection('expenses').where('userId', isEqualTo: uid).get(),
        ]),
        builder: (context, AsyncSnapshot<List<QuerySnapshot>> snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          double income = 0; // Logic tính thu nhập từ bills
          double expense = 0; // Logic tính chi phí từ expenses
          for (var d in snapshot.data![1].docs) { expense += double.tryParse(d['amount'] ?? "0") ?? 0; }

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _reportCard("TỔNG THU NHẬP", income, Colors.green),
                _reportCard("TỔNG CHI PHÍ", expense, Colors.red),
                const SizedBox(height: 20),
                const Divider(thickness: 2),
                _reportCard("LỢI NHUẬN RÒNG", income - expense, Colors.blue, isBig: true),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _reportCard(String t, double v, Color c, {bool isBig = false}) {
    return Card(
      elevation: isBig ? 5 : 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        title: Text(t, style: TextStyle(fontWeight: isBig ? FontWeight.bold : FontWeight.normal)),
        trailing: Text("${v.toStringAsFixed(0)} đ", style: TextStyle(fontSize: isBig ? 22 : 16, color: c, fontWeight: FontWeight.bold)),
      ),
    );
  }
}