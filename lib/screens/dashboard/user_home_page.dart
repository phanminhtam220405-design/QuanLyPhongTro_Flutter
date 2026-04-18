import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserHomePage extends StatelessWidget {
  const UserHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        title: const Text("TRANG CHỦ", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo, foregroundColor: Colors.white, centerTitle: true, elevation: 0,
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => FirebaseAuth.instance.signOut())],
      ),
      // SỬ DỤNG STREAMBUILDER ĐỂ LẮNG NGHE THAY ĐỔI THỜI GIAN THỰC
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          var userData = snapshot.data!;
          String roomName = userData['room_name'] ?? '';

          return SingleChildScrollView(
            child: Column(children: [
              // HEADER CHÀO HỎI
              Container(
                width: double.infinity, padding: const EdgeInsets.all(25),
                decoration: const BoxDecoration(color: Colors.indigo, borderRadius: BorderRadius.vertical(bottom: Radius.circular(30))),
                child: Row(children: [
                  const CircleAvatar(radius: 25, backgroundColor: Colors.white24, child: Icon(Icons.person, color: Colors.white)),
                  const SizedBox(width: 15),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text("Xin chào,", style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text(userData['name'] ?? "Khách hàng", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ]),
                ]),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text("Thông tin chỗ ở", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),

                  // NẾU room_name LÀ RỖNG (ADMIN ĐÃ THANH LÝ) -> HIỆN THÔNG BÁO MẤT PHÒNG
                  if (roomName == '') 
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: Container(
                        width: double.infinity, padding: const EdgeInsets.all(30),
                        child: Column(children: [
                          const Icon(Icons.info_outline, color: Colors.orange, size: 50),
                          const SizedBox(height: 10),
                          const Text("BẠN CHƯA CÓ PHÒNG THUÊ", style: TextStyle(fontWeight: FontWeight.bold)),
                          const Text("Hợp đồng đã thanh lý hoặc chưa được gán phòng.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ]),
                      ),
                    )
                  else
                    // HIỂN THỊ CARD PHÒNG NẾU ĐANG THUÊ
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 3,
                      child: Column(children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(color: Colors.indigo, borderRadius: BorderRadius.vertical(top: Radius.circular(15))),
                          child: Row(children: [
                            const Icon(Icons.key, color: Colors.white, size: 20),
                            const SizedBox(width: 10),
                            Text("Phòng của bạn: $roomName", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ]),
                        ),
                        ListTile(
                          leading: const Icon(Icons.location_on, color: Colors.redAccent),
                          title: Text(userData['house_name'] ?? 'Địa chỉ nhà'),
                          subtitle: const Text("Hợp đồng đang có hiệu lực"),
                        )
                      ]),
                    ),

                  const SizedBox(height: 25),
                  const Text("Dịch vụ tiện ích", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),
                  GridView.count(
                    shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 4, mainAxisSpacing: 10, crossAxisSpacing: 10,
                    children: [
                      _menuIcon(Icons.report, "Sự cố", Colors.orange),
                      _menuIcon(Icons.history, "Hóa đơn", Colors.blue),
                      _menuIcon(Icons.rule, "Nội quy", Colors.teal),
                      _menuIcon(Icons.phone, "Liên hệ", Colors.purple),
                    ],
                  )
                ]),
              ),
            ]),
          );
        },
      ),
    );
  }

  Widget _menuIcon(IconData icon, String label, Color color) {
    return Column(children: [
      CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color, size: 20)),
      const SizedBox(height: 5),
      Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
    ]);
  }
}