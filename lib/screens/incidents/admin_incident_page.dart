import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Màn hình quản lý sự cố phía Admin.
/// Khi cập nhật trạng thái → tự động tạo notification cho user.
class AdminIncidentPage extends StatefulWidget {
  const AdminIncidentPage({super.key});

  @override
  State<AdminIncidentPage> createState() => _AdminIncidentPageState();
}

class _AdminIncidentPageState extends State<AdminIncidentPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Danh sách tab lọc
  static const _tabs = [
    'Tất cả',
    'Mới tiếp nhận',
    'Đang xử lý',
    'Hoàn thành',
    'Từ chối',
  ];

  // ─── Cấu hình trạng thái ─────────────────────────────────────────────────
  static const _statusConfig = {
    'Mới tiếp nhận': _StatusCfg(
      color: Color(0xFF1976D2),
      bgColor: Color(0xFFE3F2FD),
      icon: Icons.fiber_new_rounded,
    ),
    'Đang xử lý': _StatusCfg(
      color: Color(0xFFF57C00),
      bgColor: Color(0xFFFFF3E0),
      icon: Icons.construction_rounded,
    ),
    'Hoàn thành': _StatusCfg(
      color: Color(0xFF388E3C),
      bgColor: Color(0xFFE8F5E9),
      icon: Icons.check_circle_rounded,
    ),
    'Từ chối': _StatusCfg(
      color: Color(0xFFD32F2F),
      bgColor: Color(0xFFFFEBEE),
      icon: Icons.cancel_rounded,
    ),
  };

  _StatusCfg _getCfg(String status) =>
      _statusConfig[status] ??
      const _StatusCfg(
          color: Color(0xFF757575),
          bgColor: Color(0xFFF5F5F5),
          icon: Icons.help_outline);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Quản lý sự cố',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs.map((tab) => _buildList(tab)).toList(),
      ),
    );
  }

  Widget _buildList(String filter) {
    Query query = FirebaseFirestore.instance.collection('incidents');
    if (filter != 'Tất cả') {
      query = query.where('status', isEqualTo: filter);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs
          ..sort((a, b) {
            final t1 = (a.data() as Map)['createdAt'] as Timestamp?;
            final t2 = (b.data() as Map)['createdAt'] as Timestamp?;
            return (t2 ?? Timestamp.now()).compareTo(t1 ?? Timestamp.now());
          });

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_rounded,
                    size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text(
                  'Không có sự cố nào${filter == 'Tất cả' ? '' : ' - $filter'}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: docs.length,
          itemBuilder: (ctx, i) => _buildAdminCard(ctx, docs[i]),
        );
      },
    );
  }

  Widget _buildAdminCard(BuildContext context, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final status = data['status'] as String? ?? 'Mới tiếp nhận';
    final cfg = _getCfg(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: cfg.bgColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Icon(cfg.icon, color: cfg.color, size: 18),
                const SizedBox(width: 8),
                Text(status,
                    style: TextStyle(
                        color: cfg.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                const Spacer(),
                Text(data['date'] ?? '',
                    style:
                        const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tiêu đề
                Row(children: [
                  const Icon(Icons.build_circle_outlined,
                      color: Color(0xFF1976D2), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(data['title'] ?? 'Sự cố',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ]),
                const SizedBox(height: 6),

                // Vị trí
                if (data['house'] != null)
                  Row(children: [
                    const Icon(Icons.location_on_outlined,
                        size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(data['house'],
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 12)),
                  ]),

                // Mô tả
                if ((data['description'] as String?)?.isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  Text(data['description'],
                      style: const TextStyle(
                          color: Colors.black87, fontSize: 13, height: 1.4)),
                ],

                // Ghi chú admin đã có
                if ((data['adminNote'] as String?)?.isNotEmpty == true) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cfg.bgColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.comment_outlined,
                            size: 14, color: cfg.color),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(data['adminNote'],
                              style: TextStyle(
                                  fontSize: 12, color: cfg.color)),
                        ),
                      ],
                    ),
                  ),
                ],

                const Divider(height: 20),

                // Buttons cập nhật trạng thái
                if (status != 'Hoàn thành' && status != 'Từ chối')
                  Row(children: [
                    if (status == 'Mới tiếp nhận')
                      Expanded(
                        child: _actionBtn(
                          label: 'Xử lý',
                          icon: Icons.construction_rounded,
                          color: const Color(0xFFF57C00),
                          onTap: () => _updateStatus(
                              context, doc, 'Đang xử lý',
                              defaultNote: 'Chủ trọ đang tiến hành xử lý sự cố của bạn.'),
                        ),
                      ),
                    if (status == 'Mới tiếp nhận') const SizedBox(width: 10),
                    Expanded(
                      child: _actionBtn(
                        label: 'Hoàn thành',
                        icon: Icons.check_circle_rounded,
                        color: const Color(0xFF388E3C),
                        onTap: () => _showUpdateDialog(
                            context, doc, 'Hoàn thành'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _actionBtn(
                        label: 'Từ chối',
                        icon: Icons.cancel_rounded,
                        color: const Color(0xFFD32F2F),
                        onTap: () =>
                            _showUpdateDialog(context, doc, 'Từ chối'),
                      ),
                    ),
                  ]),

                // Nếu đã xong → chỉ cho xem chi tiết
                if (status == 'Hoàn thành' || status == 'Từ chối')
                  Center(
                    child: Text(
                      status == 'Hoàn thành'
                          ? '✓ Đã xử lý xong'
                          : '✗ Đã từ chối',
                      style: TextStyle(
                          color: cfg.color,
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 42,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(label,
            style:
                const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }

  // ─── Cập nhật nhanh (không cần note) ─────────────────────────────────────
  Future<void> _updateStatus(
    BuildContext context,
    DocumentSnapshot doc,
    String newStatus, {
    String defaultNote = '',
  }) async {
    final data = doc.data() as Map<String, dynamic>;

    await doc.reference.update({
      'status': newStatus,
      'adminNote': defaultNote,
      'seenByUser': false,         // đánh dấu chưa đọc
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Ghi notification cho user
    await _pushNotification(
      userId: data['userId'],
      title: _notifTitle(newStatus),
      body:
          'Sự cố "${data['title']}" → $newStatus. $defaultNote',
    );
  }

  // ─── Dialog cập nhật với ghi chú ─────────────────────────────────────────
  void _showUpdateDialog(
      BuildContext context, DocumentSnapshot doc, String newStatus) {
    final data = doc.data() as Map<String, dynamic>;
    final noteCtrl = TextEditingController(
      text: newStatus == 'Hoàn thành'
          ? 'Sự cố đã được xử lý hoàn tất. Cảm ơn bạn đã phản ánh!'
          : 'Yêu cầu không đủ điều kiện xử lý.',
    );
    final costCtrl = TextEditingController();
    final cfg = _getCfg(newStatus);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Icon(cfg.icon, color: cfg.color),
          const SizedBox(width: 8),
          Text(newStatus,
              style: TextStyle(
                  color: cfg.color, fontWeight: FontWeight.bold)),
        ]),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: noteCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Ghi chú phản hồi cho khách thuê',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  hintText: 'Nhập nội dung phản hồi...',
                ),
              ),
              if (newStatus == 'Hoàn thành') ...[
                const SizedBox(height: 14),
                TextField(
                  controller: costCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Chi phí sửa chữa (đ) — tuỳ chọn',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: cfg.color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final note = noteCtrl.text.trim();

              // Cập nhật Firestore
              await doc.reference.update({
                'status': newStatus,
                'adminNote': note,
                'seenByUser': false,
                'updatedAt': FieldValue.serverTimestamp(),
              });

              // Lưu chi phí nếu có
              if (newStatus == 'Hoàn thành' &&
                  costCtrl.text.trim().isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('expenses')
                    .add({
                  'userId': FirebaseAuth.instance.currentUser?.uid,
                  'reason': 'Sửa chữa: ${data['title']}',
                  'amount': costCtrl.text.trim(),
                  'date': DateTime.now(),
                  'house': data['house'],
                });
              }

              // Gửi notification cho user
              await _pushNotification(
                userId: data['userId'],
                title: _notifTitle(newStatus),
                body: 'Sự cố "${data['title']}" → $newStatus.\n$note',
              );

              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('XÁC NHẬN',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ─── Ghi notification vào Firestore ──────────────────────────────────────
  Future<void> _pushNotification({
    required String? userId,
    required String title,
    required String body,
  }) async {
    if (userId == null) return;
    await FirebaseFirestore.instance.collection('notifications').add({
      'user_id': userId, 
      'title': title,
      'message': body,   
      'is_read': false,
      'created_at': FieldValue.serverTimestamp(), 
      'type': 'maintenance',
    });
  }

  String _notifTitle(String status) {
    switch (status) {
      case 'Đang xử lý':
        return 'Sự cố đang được xử lý';
      case 'Hoàn thành':
        return 'Sự cố đã hoàn thành';
      case 'Từ chối':
        return 'Yêu cầu bị từ chối';
      default:
        return 'Cập nhật sự cố';
    }
  }
}

// ─── Helper ───────────────────────────────────────────────────────────────────
class _StatusCfg {
  final Color color;
  final Color bgColor;
  final IconData icon;
  const _StatusCfg(
      {required this.color, required this.bgColor, required this.icon});
}