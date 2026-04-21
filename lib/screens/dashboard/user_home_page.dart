import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// import màn hình
import '../notifications/notification_page.dart';
import '../incident_page.dart';
import '../function_user/bill_history_page.dart';

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
          // 🔔 GIỮ NGUYÊN NOTIFICATION CỦA BẠN
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

          // 🚪 Logout
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 👤 USER INFO
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user?.uid)
                  .get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const LinearProgressIndicator();
                }

                var data = snapshot.data!;

                return Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.indigo,
                      child: Text(
                        data['name'][0],
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text("Chào, ${data['name']}"),
                    subtitle: Text(
                      "Phòng: ${data['house_id'] == '' ? 'Chưa gán' : data['house_id']}",
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // 💰 BILL
            const Text(
              "Hóa đơn tháng này",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            // StreamBuilder<QuerySnapshot>(
            //   stream: FirebaseFirestore.instance
            //       .collection('bills')
            //       .where('userId', isEqualTo: user?.uid)
            //       .orderBy('createdAt', descending: true)
            //       .snapshots(),
            //   builder: (context, snapshot) {
            //     if (!snapshot.hasData) {
            //       return const Center(child: CircularProgressIndicator());
            //     }

            //     var docs = snapshot.data!.docs;

            //     if (docs.isEmpty) {
            //       return const Text("Không có hóa đơn");
            //     }

            //     var bill = docs.first;

            //     String month = "${bill['month']}/${bill['year']}";

            //     return Card(
            //       elevation: 6,
            //       shape: RoundedRectangleBorder(
            //         borderRadius: BorderRadius.circular(15),
            //       ),
            //       child: ListTile(
            //         leading: const Icon(
            //           Icons.receipt_long,
            //           color: Colors.green,
            //           size: 40,
            //         ),

            //         title: Text("Tiền phòng tháng $month"),

            //         subtitle: Column(
            //           crossAxisAlignment: CrossAxisAlignment.start,
            //           children: [
            //             Text("Phòng: ${bill['roomName']}"),
            //             Text(
            //               "Trạng thái: ${bill['status']}",
            //               style: TextStyle(
            //                 color: bill['status'] == 'Đã thanh toán'
            //                     ? Colors.green
            //                     : Colors.red,
            //               ),
            //             ),
            //           ],
            //         ),

            //         trailing: Text(
            //           _formatMoney(bill['totalAmount']),
            //           style: const TextStyle(
            //             fontWeight: FontWeight.bold,
            //             color: Colors.red,
            //           ),
            //         ),
            //       ),
            //     );
            //   },
            // ),

            const SizedBox(height: 20),

            // ⚡ MENU
            const Text(
              "Tiện ích nhanh",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                // 🚨 INCIDENT
                _menu(context, "Báo hỏng hóc", Icons.report, Colors.orange, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const IncidentScreen()),
                  );
                }),

                // 📜 BILL HISTORY
                _menu(
                  context,
                  "Lịch sử hóa đơn",
                  Icons.history,
                  Colors.blue,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BillHistoryPage(),
                      ),
                    );
                  },
                ),

                // 📋 RULE
                _menu(context, "Nội quy trọ", Icons.rule, Colors.teal, () {
                  showDialog(
                    context: context,
                    builder: (_) => const AlertDialog(
                      title: Text("Nội quy"),
                      content: Text("Không gây ồn sau 22h..."),
                    ),
                  );
                }),

                // ☎ CONTACT
                _menu(
                  context,
                  "Liên hệ chủ nhà",
                  Icons.phone,
                  Colors.purple,
                  () {
                    showDialog(
                      context: context,
                      builder: (_) => const AlertDialog(
                        title: Text("Liên hệ"),
                        content: Text("SĐT: 090xxxxxxx"),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 🎨 MENU UI
  Widget _menu(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 4,
        color: color.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  // 💰 FORMAT TIỀN
  String _formatMoney(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        ) +
        'đ';
  }
}
