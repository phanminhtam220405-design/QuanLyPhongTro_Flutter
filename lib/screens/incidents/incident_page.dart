import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/common_widgets.dart';

class IncidentScreen extends StatefulWidget {
  const IncidentScreen({super.key});
  @override
  State<IncidentScreen> createState() => _IncidentScreenState();
}

class _IncidentScreenState extends State<IncidentScreen> {
  final uid = FirebaseAuth.instance.currentUser!.uid;

  // ─── Cấu hình trạng thái ───────────────────────────────────────────────────
  static const _statusConfig = {
    'Mới tiếp nhận': _StatusConfig(
      color: Color(0xFF1976D2),
      bgColor: Color(0xFFE3F2FD),
      icon: Icons.fiber_new_rounded,
      label: 'Mới tiếp nhận',
    ),
    'Đang xử lý': _StatusConfig(
      color: Color(0xFFF57C00),
      bgColor: Color(0xFFFFF3E0),
      icon: Icons.construction_rounded,
      label: 'Đang xử lý',
    ),
    'Hoàn thành': _StatusConfig(
      color: Color(0xFF388E3C),
      bgColor: Color(0xFFE8F5E9),
      icon: Icons.check_circle_rounded,
      label: 'Hoàn thành',
    ),
    'Từ chối': _StatusConfig(
      color: Color(0xFFD32F2F),
      bgColor: Color(0xFFFFEBEE),
      icon: Icons.cancel_rounded,
      label: 'Từ chối',
    ),
  };

  _StatusConfig _getConfig(String status) =>
      _statusConfig[status] ??
      const _StatusConfig(
        color: Color(0xFF757575),
        bgColor: Color(0xFFF5F5F5),
        icon: Icons.help_outline,
        label: 'Không rõ',
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Sự cố & Bảo trì',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('incidents')
            .where('userId', isEqualTo: uid)
            .snapshots(),
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
                  Icon(Icons.build_circle_outlined,
                      size: 72, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text(
                    'Chưa có sự cố nào được ghi nhận.',
                    style: TextStyle(color: Colors.grey, fontSize: 15),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(15, 15, 15, 100),
            itemCount: docs.length,
            itemBuilder: (context, index) =>
                _buildIncidentCard(context, docs[index]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1976D2),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Gửi sự cố',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: () => _showAddIncidentForm(context),
      ),
    );
  }

  Widget _buildIncidentCard(BuildContext context, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final status = data['status'] as String? ?? 'Mới tiếp nhận';
    final cfg = _getConfig(status);
    final adminNote = data['adminNote'] as String?;
    final hasNewUpdate = data['seenByUser'] == false && status != 'Mới tiếp nhận';

    return GestureDetector(
      onTap: () {
        // Đánh dấu user đã xem khi mở card
        if (hasNewUpdate) {
          doc.reference.update({'seenByUser': true});
        }
        _showDetailBottomSheet(context, doc);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: hasNewUpdate
              ? Border.all(color: cfg.color, width: 2)
              : Border.all(color: Colors.transparent),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header màu theo status ──────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: cfg.bgColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Icon(cfg.icon, color: cfg.color, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    cfg.label,
                    style: TextStyle(
                      color: cfg.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  if (hasNewUpdate)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: cfg.color,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '● Cập nhật mới',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (!hasNewUpdate)
                    Text(
                      data['date'] ?? '',
                      style:
                          const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                ],
              ),
            ),

            // ── Nội dung ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.build_circle_outlined,
                          color: Color(0xFF1976D2), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          data['title'] ?? 'Sự cố',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  if (data['house'] != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 15, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          data['house'],
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ],

                  // ── Ghi chú từ chủ trọ ─────────────────────────────────
                  if (adminNote != null && adminNote.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cfg.bgColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: cfg.color.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.comment_outlined,
                                  size: 14, color: cfg.color),
                              const SizedBox(width: 6),
                              Text(
                                'Phản hồi từ chủ trọ',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: cfg.color,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            adminNote,
                            style: TextStyle(
                                fontSize: 13, color: cfg.color),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // ── Dòng trạng thái timeline mini ─────────────────────
                  const SizedBox(height: 14),
                  _buildStatusTimeline(status),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Timeline nhỏ dưới card để user thấy tiến trình
  Widget _buildStatusTimeline(String currentStatus) {
    final steps = ['Mới tiếp nhận', 'Đang xử lý', 'Hoàn thành'];
    final isRejected = currentStatus == 'Từ chối';

    if (isRejected) {
      return Row(
        children: [
          const Icon(Icons.cancel_rounded, color: Color(0xFFD32F2F), size: 18),
          const SizedBox(width: 6),
          const Text(
            'Yêu cầu đã bị từ chối',
            style: TextStyle(
                color: Color(0xFFD32F2F),
                fontSize: 12,
                fontWeight: FontWeight.w600),
          ),
        ],
      );
    }

    final currentIndex = steps.indexOf(currentStatus);

    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          // đường nối
          final stepIndex = i ~/ 2;
          final isCompleted = stepIndex < currentIndex;
          return Expanded(
            child: Container(
              height: 2,
              color: isCompleted
                  ? const Color(0xFF388E3C)
                  : Colors.grey.shade200,
            ),
          );
        }
        // dot
        final stepIndex = i ~/ 2;
        final isCompleted = stepIndex <= currentIndex;
        final isCurrent = stepIndex == currentIndex;
        final cfg = _getConfig(steps[stepIndex]);

        return Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isCurrent ? 20 : 14,
              height: isCurrent ? 20 : 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted ? cfg.color : Colors.grey.shade200,
                border: isCurrent
                    ? Border.all(color: cfg.color.withOpacity(0.3), width: 3)
                    : null,
              ),
              child: isCompleted
                  ? Icon(Icons.check,
                      size: isCurrent ? 12 : 9, color: Colors.white)
                  : null,
            ),
            const SizedBox(height: 4),
            Text(
              steps[stepIndex].replaceAll(' ', '\n'),
              style: TextStyle(
                fontSize: 9,
                color: isCompleted ? cfg.color : Colors.grey,
                fontWeight:
                    isCurrent ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        );
      }),
    );
  }

  // ─── Bottom sheet chi tiết ─────────────────────────────────────────────────
  void _showDetailBottomSheet(BuildContext context, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final status = data['status'] as String? ?? 'Mới tiếp nhận';
    final cfg = _getConfig(status);
    final adminNote = data['adminNote'] as String?;
    final canEdit = status == 'Mới tiếp nhận';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.all(24),
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Status badge lớn
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: cfg.bgColor,
                    borderRadius: BorderRadius.circular(30),
                    border:
                        Border.all(color: cfg.color.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(cfg.icon, color: cfg.color, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        cfg.label,
                        style: TextStyle(
                          color: cfg.color,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 10),

              _detailRow(Icons.build_circle_outlined, 'Vấn đề',
                  data['title'] ?? ''),
              _detailRow(Icons.location_on_outlined, 'Vị trí',
                  data['house'] ?? ''),
              _detailRow(Icons.notes_rounded, 'Mô tả',
                  data['description'] ?? 'Không có mô tả'),
              _detailRow(Icons.calendar_today_outlined, 'Ngày gửi',
                  data['date'] ?? ''),

              // Phản hồi admin
              if (adminNote != null && adminNote.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cfg.bgColor,
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: cfg.color.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.comment_rounded,
                              color: cfg.color, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Phản hồi từ chủ trọ',
                            style: TextStyle(
                              color: cfg.color,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(adminNote,
                          style: TextStyle(
                              fontSize: 14,
                              color: cfg.color,
                              height: 1.5)),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Buttons
              if (canEdit) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showEditIncidentForm(context, doc);
                        },
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Chỉnh sửa'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1976D2),
                          side: const BorderSide(
                              color: Color(0xFF1976D2)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _confirmDelete(context, doc);
                        },
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Xóa'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Đóng',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF1976D2)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Form gửi sự cố ───────────────────────────────────────────────────────
  void _showAddIncidentForm(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final houseCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFFF5F5F5),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Gửi yêu cầu sửa chữa',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1976D2)),
            ),
            const SizedBox(height: 20),
            whiteInput('Tên khu trọ/Phòng *', 'Ví dụ: Nhà Quận 3 - P101',
                houseCtrl),
            const SizedBox(height: 12),
            whiteInput('Vấn đề gặp phải *', 'Ví dụ: Hư vòi sen', titleCtrl),
            const SizedBox(height: 12),
            whiteInput('Mô tả chi tiết', 'Ví dụ: Nước chảy yếu...', descCtrl),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.send_rounded, color: Colors.white),
                label: const Text(
                  'GỬI YÊU CẦU',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                ),
                onPressed: () async {
                  if (titleCtrl.text.trim().isEmpty ||
                      houseCtrl.text.trim().isEmpty) return;

                  await FirebaseFirestore.instance
                      .collection('incidents')
                      .add({
                    'userId': uid,
                    'title': titleCtrl.text.trim(),
                    'description': descCtrl.text.trim(),
                    'house': houseCtrl.text.trim(),
                    'status': 'Mới tiếp nhận',
                    'date': DateTime.now().toString().split(' ')[0],
                    'createdAt': FieldValue.serverTimestamp(),
                    'seenByUser': true,
                    'adminNote': '',
                  });

                  if (context.mounted) Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ─── Edit / Delete ─────────────────────────────────────────────────────────
  void _showEditIncidentForm(BuildContext context, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final titleCtrl = TextEditingController(text: data['title']);
    final descCtrl = TextEditingController(text: data['description']);
    final houseCtrl = TextEditingController(text: data['house']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFFF5F5F5),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Chỉnh sửa sự cố',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            whiteInput('Tên khu trọ', '', houseCtrl),
            const SizedBox(height: 12),
            whiteInput('Vấn đề', '', titleCtrl),
            const SizedBox(height: 12),
            whiteInput('Mô tả', '', descCtrl),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  await doc.reference.update({
                    'title': titleCtrl.text.trim(),
                    'description': descCtrl.text.trim(),
                    'house': houseCtrl.text.trim(),
                  });
                  if (context.mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('CẬP NHẬT',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, DocumentSnapshot doc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa sự cố'),
        content: const Text('Bạn có chắc muốn xóa không?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              await doc.reference.delete();
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('XÓA',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ─── Helper data class ─────────────────────────────────────────────────────────
class _StatusConfig {
  final Color color;
  final Color bgColor;
  final IconData icon;
  final String label;
  const _StatusConfig(
      {required this.color,
      required this.bgColor,
      required this.icon,
      required this.label});
}