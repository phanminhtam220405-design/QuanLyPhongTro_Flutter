import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../notifications/notification_page.dart';

class UserHomePage extends StatelessWidget {
  const UserHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Người Thuê Trọ"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          // Nút thông báo
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationPage(),
                    ),
                  );
                },
              ),
              // Badge hiển thị số lượng thông báo chưa đọc
              Positioned(
                right: 8,
                top: 8,
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('notifications')
                      .where('user_id', isEqualTo: user?.uid)
                      .where('is_read', isEqualTo: false)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    int unreadCount = snapshot.data!.docs.length;
                    return Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        unreadCount > 9 ? '9+' : '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          // Nút đăng xuất
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(user?.uid).get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const LinearProgressIndicator();
                var userData = snapshot.data!;
                return Card(
                  color: Colors.indigo.shade50,
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text("Chào, ${userData['name']}"),
                    subtitle: Text("Phòng: ${userData['house_id'] == '' ? 'Chưa gán' : userData['house_id']}"),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            const Text("Hóa đơn tháng này", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            
            Card(
              elevation: 4,
              child: ListTile(
                leading: const Icon(Icons.receipt_long, color: Colors.green, size: 40),
                title: const Text("Tiền phòng tháng 04/2026"),
                subtitle: const Text("Trạng thái: Chưa thanh toán"),
                trailing: const Text("3.000.000đ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
              ),
            ),

            const SizedBox(height: 20),
            const Text("Tiện ích nhanh", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                _buildMenuButton(context, "Báo hỏng hóc", Icons.report_problem, Colors.orange, () {
                }),
                _buildMenuButton(context, "Lịch sử hóa đơn", Icons.history, Colors.blue, () {
                }),
                _buildMenuButton(context, "Nội quy trọ", Icons.gavel, Colors.teal, () {}),
                _buildMenuButton(context, "Liên hệ chủ nhà", Icons.contact_phone, Colors.purple, () {}),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Card(
        color: color.withOpacity(0.1),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(title, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}