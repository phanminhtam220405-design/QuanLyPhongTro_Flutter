import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminSendNotificationPage extends StatefulWidget {
  const AdminSendNotificationPage({super.key});

  @override
  State<AdminSendNotificationPage> createState() => _AdminSendNotificationPageState();
}

class _AdminSendNotificationPageState extends State<AdminSendNotificationPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  // Các biến để quản lý trạng thái lựa chọn
  String _selectedType = 'general';
  String _recipientType = 'all'; // all, specific_room, specific_user
  String? _selectedRoomId;
  String? _selectedUserId;
  bool _isLoading = false;
  // Danh sách loại thông báo với icon và màu sắc tương ứng
  final List<Map<String, dynamic>> _notificationTypes = [
    {'value': 'general', 'label': 'Thông báo chung', 'icon': Icons.notifications},
    {'value': 'bill', 'label': 'Hóa đơn', 'icon': Icons.receipt_long},
    {'value': 'payment', 'label': 'Thanh toán', 'icon': Icons.payment},
    {'value': 'maintenance', 'label': 'Bảo trì/Sửa chữa', 'icon': Icons.build},
    {'value': 'announcement', 'label': 'Thông báo quan trọng', 'icon': Icons.campaign},
    {'value': 'warning', 'label': 'Cảnh báo', 'icon': Icons.warning},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }
  // Hàm gửi thông báo
  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      
      // Lấy danh sách user_id dựa vào loại người nhận
      List<String> recipientUserIds = [];

      if (_recipientType == 'all') {
        // Gửi cho tất cả khách thuê
        final usersSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'user')
            .get();
        recipientUserIds = usersSnapshot.docs.map((doc) => doc.id).toList();
      } else if (_recipientType == 'specific_room' && _selectedRoomId != null) {
        // Gửi cho khách thuê trong phòng cụ thể
        final usersSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('house_id', isEqualTo: _selectedRoomId)
            .get();
        recipientUserIds = usersSnapshot.docs.map((doc) => doc.id).toList();
      } else if (_recipientType == 'specific_user' && _selectedUserId != null) {
        // Gửi cho người dùng cụ thể
        recipientUserIds = [_selectedUserId!];
      }

      if (recipientUserIds.isEmpty) {
        throw Exception('Không tìm thấy người nhận');
      }

      // Tạo thông báo cho từng người nhận
      final batch = FirebaseFirestore.instance.batch();
      
      for (String userId in recipientUserIds) {
        final notificationRef = FirebaseFirestore.instance.collection('notifications').doc();
        batch.set(notificationRef, {
          'user_id': userId,
          'title': _titleController.text.trim(),
          'message': _messageController.text.trim(),
          'type': _selectedType,
          'is_read': false,
          'created_at': FieldValue.serverTimestamp(),
          'sender_id': currentUser?.uid,
          'sender_name': currentUser?.displayName ?? 'Chủ trọ',
        });
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã gửi thông báo đến ${recipientUserIds.length} người'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gửi thông báo"),
        backgroundColor: Color(0xFF1976D2),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Chọn loại thông báo
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Loại thông báo',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _notificationTypes.map((type) {
                        final isSelected = _selectedType == type['value'];
                        return InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () {
                            setState(() {
                              _selectedType = type['value'] as String;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF1976D2) : Colors.transparent,
                              border: Border.all(
                                color: isSelected ? const Color(0xFF1976D2) : Colors.grey.shade400,
                              ),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  type['icon'] as IconData,
                                  size: 18,
                                  color: isSelected ? Colors.white : Colors.indigo,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  type['label'] as String,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Chọn người nhận
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Người nhận',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    RadioListTile(
                      title: const Text('Tất cả khách thuê'),
                      value: 'all',
                      groupValue: _recipientType,
                      onChanged: (value) {
                        setState(() => _recipientType = value as String);
                      },
                    ),
                    RadioListTile(
                      title: const Text('Theo phòng cụ thể'),
                      value: 'specific_room',
                      groupValue: _recipientType,
                      onChanged: (value) {
                        setState(() => _recipientType = value as String);
                      },
                    ),
                    if (_recipientType == 'specific_room')
                      Padding(
                        padding: const EdgeInsets.only(left: 32, top: 8),
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('rooms')
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const CircularProgressIndicator();
                            }
                            return DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Chọn phòng',
                                border: OutlineInputBorder(),
                              ),
                              initialValue: _selectedRoomId,
                              items: snapshot.data!.docs.map((doc) {
                                return DropdownMenuItem(
                                  value: doc.id,
                                  child: Text(doc['name'] ?? doc.id),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() => _selectedRoomId = value);
                              },
                            );
                          },
                        ),
                      ),
                    RadioListTile(
                      title: const Text('Người dùng cụ thể'),
                      value: 'specific_user',
                      groupValue: _recipientType,
                      onChanged: (value) {
                        setState(() => _recipientType = value as String);
                      },
                    ),
                    if (_recipientType == 'specific_user')
                      Padding(
                        padding: const EdgeInsets.only(left: 32, top: 8),
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .where('role', isEqualTo: 'user')
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const CircularProgressIndicator();
                            }
                            return DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Chọn người dùng',
                                border: OutlineInputBorder(),
                              ),
                              initialValue: _selectedUserId,
                              items: snapshot.data!.docs.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                return DropdownMenuItem(
                                  value: doc.id,
                                  child: Text(data['name'] ?? doc.id),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() => _selectedUserId = value);
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tiêu đề
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Tiêu đề',
                    hintText: 'Nhập tiêu đề thông báo',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập tiêu đề';
                    }
                    return null;
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Nội dung
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextFormField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    labelText: 'Nội dung',
                    hintText: 'Nhập nội dung thông báo',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 5,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập nội dung';
                    }
                    return null;
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Nút gửi
            ElevatedButton(
              onPressed: _isLoading ? null : _sendNotification,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1976D2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.send),
                        SizedBox(width: 8),
                        Text(
                          'Gửi thông báo',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}