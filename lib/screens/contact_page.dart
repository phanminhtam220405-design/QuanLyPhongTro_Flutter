import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 1. Chuyển từ StatelessWidget sang StatefulWidget để dùng được setState và Controllers
class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  // 2. Đưa Controllers ra ngoài hàm build để không bị reset khi render lại UI
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController messageController = TextEditingController();

  String selectedType = 'Góp ý';
  bool isSending = false; // Thêm biến để hiện loading nếu muốn

  // Hàm xử lý gửi góp ý
  void _submitFeedback() async {
    if (nameController.text.trim().isEmpty ||
        messageController.text.trim().isEmpty) {
      _showMessage('Vise lòng điền đầy đủ họ tên và nội dung!');
      return;
    }

    try {
      // 3. Lưu vào Firebase (Dùng đúng các Controller đã khai báo)
      await FirebaseFirestore.instance.collection('feedback').add({
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'phone': phoneController.text.trim(),
        'content': messageController.text.trim(),
        'type': selectedType,
        'date': FieldValue.serverTimestamp(), // Dùng thời gian server cho chuẩn
      });

      _showSuccessDialog();
    } catch (e) {
      _showMessage('Lỗi khi gửi: $e');
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 30),
            SizedBox(width: 10),
            Text('Gửi thành công!'),
          ],
        ),
        content: const Text(
          'Cảm ơn bạn đã gửi phản hồi. Chúng tôi sẽ xem xét sớm nhất!',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearForm();
            },
            child: const Text('ĐÓNG'),
          ),
        ],
      ),
    );
  }

  void _clearForm() {
    nameController.clear();
    emailController.clear();
    phoneController.clear();
    messageController.clear();
    setState(() {
      selectedType = 'Góp ý';
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1976D2),
        elevation: 0,
        title: const Text(
          'Liên hệ, góp ý',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              "Mọi ý kiến của bạn sẽ giúp chúng tôi hoàn thiện ứng dụng tốt hơn.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 25),

            // Card Thông tin liên hệ
            _buildContactInfoCard(),

            const SizedBox(height: 25),

            // Form Nhập liệu
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Gửi góp ý của bạn",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(nameController, 'Họ và tên *', Icons.person),
                  _buildTextField(
                    emailController,
                    'Email',
                    Icons.email,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  _buildTextField(
                    phoneController,
                    'Số điện thoại',
                    Icons.phone,
                    keyboardType: TextInputType.phone,
                  ),
                  _buildTextField(
                    messageController,
                    'Nội dung góp ý *',
                    Icons.message,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1976D2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _submitFeedback,
                      child: const Text(
                        "GỬI GÓP Ý",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget con để code gọn hơn
  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildContactInfoCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            _contactItem(Icons.email, 'Email', 'support@quanlytro.vn'),
            const Divider(),
            _contactItem(Icons.phone, 'Hotline', '1900 xxxx'),
          ],
        ),
      ),
    );
  }

  Widget _contactItem(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}
