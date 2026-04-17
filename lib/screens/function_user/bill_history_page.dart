import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BillHistoryPage extends StatelessWidget {
  const BillHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("Lịch sử hóa đơn")),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bills')
            .where('userId', isEqualTo: uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const CircularProgressIndicator();
          }

          var docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var bill = docs[index];

              return ListTile(
                title: Text("Tháng ${bill['month']}/${bill['year']}"),
                subtitle: Text("Trạng thái: ${bill['status']}"),
                trailing: Text("${bill['totalAmount']}đ"),
              );
            },
          );
        },
      ),
    );
  }
}
