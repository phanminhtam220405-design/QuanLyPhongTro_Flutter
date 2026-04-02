import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final msg = TextEditingController();
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(backgroundColor: const Color(0xFF1976D2), foregroundColor: Colors.white, title: const Text("Liên hệ & Góp ý")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text("Mọi ý kiến của bạn sẽ giúp chúng tôi hoàn thiện ứng dụng tốt hơn.", textAlign: TextAlign.center),
            const SizedBox(height: 25),
            // Form trắng bo góc
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade300)),
              child: Column(
                children: [
                  const Row(children: [Icon(Icons.email, color: Colors.blue, size: 18), SizedBox(width: 10), Text("Nội dung góp ý", style: TextStyle(fontWeight: FontWeight.bold))]),
                  const SizedBox(height: 10),
                  TextField(controller: msg, maxLines: 6, decoration: const InputDecoration(hintText: "Hãy cho chúng tôi biết bạn cần thêm tính năng gì...", border: InputBorder.none)),
                  const Divider(),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1976D2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: () {
                        if (msg.text.isNotEmpty) {
                          FirebaseFirestore.instance.collection('feedback').add({'content': msg.text, 'date': DateTime.now()});
                          msg.clear();
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cảm ơn góp ý của bạn!")));
                        }
                      },
                      child: const Text("GỬI GÓP Ý", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Text("Hotline hỗ trợ: 1900 xxxx", style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}