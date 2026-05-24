import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// Đảm bảo các đường dẫn import này đúng với project của bạn
import '../notifications/notification_page.dart';
import '../incidents/incident_page.dart';
import '../function_user/bill_history_page.dart';

class UserHomePage extends StatelessWidget {
  const UserHomePage({super.key});

  // Hàm format tiền tệ VNĐ
  String _formatCurrency(dynamic amount) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    return formatter.format(amount ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F9),
      appBar: AppBar(
        title: const Text("Trang Khách Thuê", style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          _buildNotificationIcon(context, user),
          IconButton(
            icon: const Icon(Icons.power_settings_new),
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildHeader(user),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Hóa đơn tháng này", 
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF263238))),
                  const SizedBox(height: 12),
                  _buildCurrentBillCard(user),
                  const SizedBox(height: 24),
                  const Text("Tiện ích nhanh", 
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF263238))),
                  const SizedBox(height: 12),
                  _buildQuickMenu(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(User? user) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF1565C0),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      child: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(user?.uid).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox(height: 80);
          var data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          return Row(
            children: [
              CircleAvatar(
                radius: 35,
                backgroundColor: Colors.white24,
                child: Text(
                  data['name'] != null ? data['name'][0].toUpperCase() : "?",
                  style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Xin chào 👋", style: TextStyle(color: Colors.white70, fontSize: 14)),
                    Text(data['name'] ?? "Khách thuê",
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Chip(
                      label: Text(
                        data['room_name'] == '' || data['room_name'] == null ? "Chưa nhận phòng" : "Phòng: ${data['room_name']}",
                        style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCurrentBillCard(User? user) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bills')
          .where('userId', isEqualTo: user?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return _buildStatusBox("Lỗi kết nối dữ liệu");
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        var docs = snapshot.data!.docs;
        if (docs.isEmpty) return _buildStatusBox("Hiện tại bạn không có hóa đơn mới");

        // Sắp xếp local để lấy hóa đơn mới nhất (tránh lỗi Index Firestore)
        docs.sort((a, b) {
          var t1 = a.get('createdAt') as Timestamp?;
          var t2 = b.get('createdAt') as Timestamp?;
          return (t2 ?? Timestamp.now()).compareTo(t1 ?? Timestamp.now());
        });

        var bill = docs.first.data() as Map<String, dynamic>;
        String status = bill['status'] ?? "Đã báo";
        double total = double.tryParse(bill['totalAmount'].toString()) ?? 0;
        double paid = double.tryParse(bill['paidAmount']?.toString() ?? '0') ?? 0;
        double remaining = total - paid;
        
        Color statusColor = status == "Đã đóng" ? Colors.green : (status == "Đóng một phần" ? Colors.orange : Colors.red);

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Hóa đơn kỳ ${bill['month']}/${bill['year']}", 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(status == "Đã đóng" ? "Đã tất toán" : "Còn nợ: ${_formatCurrency(remaining)}",
                          style: TextStyle(color: status == "Đã đóng" ? Colors.green : Colors.red, fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
              const Divider(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Tổng hóa đơn:", style: TextStyle(fontSize: 15)),
                  Text(_formatCurrency(total), style: const TextStyle(fontSize: 19, color: Colors.blue, fontWeight: FontWeight.bold)),
                ],
              ),
              if (paid > 0) ...[
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Đã đóng trước:", style: TextStyle(fontSize: 14, color: Colors.grey)),
                    Text(_formatCurrency(paid), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ),
              ]
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusBox(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Center(child: Text(msg, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500))),
    );
  }

  Widget _buildQuickMenu(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      childAspectRatio: 1.2,
      children: [
        _buildMenuButton(context, "Báo hỏng", Icons.build_circle, Colors.orange, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => IncidentScreen()));
        }),
        _buildMenuButton(context, "Lịch sử hóa đơn", Icons.history_edu, Colors.blue, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => BillHistoryPage()));
        }),
        _buildMenuButton(context, "Nội quy", Icons.gavel_rounded, Colors.teal, () => _showModal(context, "Nội quy", "1. Giữ vệ sinh chung\n2. Không ồn sau 23h")),
        _buildMenuButton(context, "Liên hệ", Icons.phone_in_talk, Colors.purple, () => _showModal(context, "Liên hệ", "Hotline: 0901.234.567")),
      ],
    );
  }

  Widget _buildMenuButton(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.1))),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 40, color: color), const SizedBox(height: 8), Text(title, style: const TextStyle(fontWeight: FontWeight.bold))]),
      ),
    );
  }

  Widget _buildNotificationIcon(BuildContext context, User? user) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('notifications').where('user_id', isEqualTo: user?.uid).where('is_read', isEqualTo: false).snapshots(),
      builder: (context, snapshot) {
        int count = snapshot.hasData ? snapshot.data!.docs.length : 0;
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(icon: const Icon(Icons.notifications_none_rounded), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NotificationPage()))),
            if (count > 0)
              Positioned(right: 8, top: 8, child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: Text(count > 9 ? '9+' : '$count', style: const TextStyle(fontSize: 8, color: Colors.white)))),
          ],
        );
      },
    );
  }

  void _handleLogout(BuildContext context) {
    showDialog(context: context, builder: (context) => AlertDialog(title: const Text("Đăng xuất?"), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")), TextButton(onPressed: () async { await FirebaseAuth.instance.signOut(); Navigator.pushReplacementNamed(context, '/login'); }, child: const Text("Đồng ý"))]));
  }

  void _showModal(BuildContext context, String title, String content) {
    showDialog(context: context, builder: (_) => AlertDialog(title: Text(title), content: Text(content)));
  }
}