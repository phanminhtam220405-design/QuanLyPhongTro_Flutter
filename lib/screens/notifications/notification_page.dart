import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Thông báo"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          // Nút đánh dấu tất cả đã đọc
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Đánh dấu tất cả đã đọc',
            onPressed: () async {
              final batch = FirebaseFirestore.instance.batch();
              final notifications = await FirebaseFirestore.instance
                  .collection('notifications')
                  .where('user_id', isEqualTo: user?.uid)
                  .where('is_read', isEqualTo: false)
                  .get();

              for (var doc in notifications.docs) {
                batch.update(doc.reference, {'is_read': true});
              }
              await batch.commit();

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã đánh dấu tất cả đã đọc')),
              );
            },
          ),
        ],
      ),
      // Hiển thị danh sách thông báo
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('user_id', isEqualTo: user?.uid)
            .orderBy('created_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có thông báo nào',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          // Hiển thị chi tiết thông báo khi nhấn vào
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final notificationData = snapshot.data!.docs[index];
              final data = notificationData.data() as Map<String, dynamic>;
              final bool isRead = data['is_read'] ?? false;
              final String type = data['type'] ?? 'general';
              final String title = data['title'] ?? 'Thông báo';
              final String message = data['message'] ?? '';
              final Timestamp? timestamp = data['created_at'];

              // Cho phép xóa thông báo bằng cách vuốt sang trái
              return Dismissible(
                key: Key(notificationData.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) async {
                  await FirebaseFirestore.instance
                      .collection('notifications')
                      .doc(notificationData.id)
                      .delete();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã xóa thông báo')),
                  );
                },
                // Hiển thị thông báo
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  color: isRead ? Colors.white : Colors.indigo.shade50,
                  elevation: isRead ? 1 : 3,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getNotificationColor(type).withOpacity(0.2),
                      child: Icon(
                        _getNotificationIcon(type),
                        color: _getNotificationColor(type),
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatTimestamp(timestamp),
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    isThreeLine: true,
                    onTap: () async {
                      // Đánh dấu đã đọc khi nhấn vào
                      if (!isRead) {
                        await FirebaseFirestore.instance
                            .collection('notifications')
                            .doc(notificationData.id)
                            .update({'is_read': true});
                      }

                      // Hiển thị chi tiết thông báo
                      _showNotificationDetail(context, title, message, timestamp, type);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Lấy icon theo loại thông báo
  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'bill':
        return Icons.receipt_long;
      case 'payment':
        return Icons.payment;
      case 'maintenance':
        return Icons.build;
      case 'announcement':
        return Icons.campaign;
      case 'warning':
        return Icons.warning;
      default:
        return Icons.notifications;
    }
  }

  // Lấy màu theo loại thông báo
  Color _getNotificationColor(String type) {
    switch (type) {
      case 'bill':
        return Colors.orange;
      case 'payment':
        return Colors.green;
      case 'maintenance':
        return Colors.blue;
      case 'announcement':
        return Colors.indigo;
      case 'warning':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Format thời gian
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';

    final DateTime dateTime = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    }
  }

  // Hiển thị chi tiết thông báo
  void _showNotificationDetail(
    BuildContext context,
    String title,
    String message,
    Timestamp? timestamp,
    String type,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getNotificationIcon(type),
              color: _getNotificationColor(type),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    timestamp != null
                        ? DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate())
                        : '',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}