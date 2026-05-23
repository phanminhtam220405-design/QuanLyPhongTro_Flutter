import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
        title: const Text(
          "Trang khách thuê",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        actions: [
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

          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF5F7FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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

                return Container(
                  padding: const EdgeInsets.all(20),

                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1976D2), Color(0xFF0D47A1)],
                    ),

                    borderRadius: BorderRadius.circular(24),

                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),

                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.white24,

                        child: Text(
                          data['name'][0],

                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                      ),

                      const SizedBox(width: 18),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            const Text(
                              "Xin chào 👋",

                              style: TextStyle(color: Colors.white70),
                            ),

                            const SizedBox(height: 5),

                            Text(
                              data['name'],

                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 10),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),

                              decoration: BoxDecoration(
                                color: Colors.white24,

                                borderRadius: BorderRadius.circular(30),
                              ),

                              child: Text(
                                data['room_name'] == ''
                                    ? "Chưa có phòng"
                                    : "Phòng ${data['room_name']}",

                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            const Text(
              "Hóa đơn tháng này",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bills')
                  .where('userId', isEqualTo: user?.uid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),

              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20),

                    decoration: BoxDecoration(
                      color: Colors.white,

                      borderRadius: BorderRadius.circular(20),
                    ),

                    child: const Center(child: Text("Chưa có hóa đơn")),
                  );
                }

                var bill = docs.first;

                bool paid = bill['status'] == 'Đã thanh toán';

                return Container(
                  padding: const EdgeInsets.all(20),

                  decoration: BoxDecoration(
                    color: Colors.white,

                    borderRadius: BorderRadius.circular(22),

                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),

                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,

                            backgroundColor: paid
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),

                            child: Icon(
                              Icons.receipt_long,

                              color: paid ? Colors.green : Colors.red,
                            ),
                          ),

                          const SizedBox(width: 14),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,

                              children: [
                                Text(
                                  "Hóa đơn ${bill['month']}/${bill['year']}",

                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                  ),
                                ),

                                const SizedBox(height: 4),

                                Text(
                                  bill['roomName'],
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),

                            decoration: BoxDecoration(
                              color: paid
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),

                              borderRadius: BorderRadius.circular(30),
                            ),

                            child: Text(
                              bill['status'],

                              style: TextStyle(
                                color: paid ? Colors.green : Colors.red,

                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,

                        children: [
                          const Text(
                            "Tổng thanh toán",

                            style: TextStyle(fontSize: 16),
                          ),

                          Text(
                            _formatMoney(bill['totalAmount']),

                            style: const TextStyle(
                              fontSize: 24,
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

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
        elevation: 2,
        shadowColor: Colors.black12,
        color: color.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
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
