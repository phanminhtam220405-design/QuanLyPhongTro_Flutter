import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Colors.blue, Colors.indigo]),
        ),
        child: Center(
          child: Card(
            margin: const EdgeInsets.all(25),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(25),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.account_circle,
                    size: 80,
                    color: Colors.blue,
                  ),
                  const Text(
                    "ĐĂNG NHẬP CHỦ TRỌ",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: "Email",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Mật khẩu",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      // Thay thế đoạn onPressed của nút ĐĂNG NHẬP
                      onPressed: () async {
                        try {
                          // 1. Đăng nhập Auth
                          UserCredential userCredential = await FirebaseAuth
                              .instance
                              .signInWithEmailAndPassword(
                                email: emailController.text.trim(),
                                password: passwordController.text.trim(),
                              );

                          // 2. Lấy UID và check role từ Firestore
                          String uid = userCredential.user!.uid;
                          
                          // CODE FIX MỚI: Thêm timeout để không bao giờ bị treo app ở dòng này
                          DocumentSnapshot userDoc = await FirebaseFirestore
                              .instance
                              .collection('users')
                              .doc(uid)
                              .get()
                              .timeout(
                                const Duration(seconds: 10),
                                onTimeout: () => throw "Máy chủ phản hồi quá lâu, vui lòng thử lại!",
                              );

                          if (userDoc.exists && context.mounted) {
                            // CODE FIX MỚI: Lấy dữ liệu an toàn, chống crash nếu field 'role' bị thiếu
                            Map<String, dynamic>? data = userDoc.data() as Map<String, dynamic>?;
                            String role = (data != null && data.containsKey('role')) ? data['role'] : 'user';

                            // 3. Điều hướng dựa trên Role
                            if (role == 'admin') {
                              // Nếu là admin, vào trang Dashboard chủ trọ
                              Navigator.pushReplacementNamed(
                                context,
                                '/dashboard',
                              );
                            } else {
                              // Nếu là user, vào trang dành cho người thuê
                              Navigator.pushReplacementNamed(
                                context,
                                '/user_home',
                              );
                            }
                          } else {
                            throw "Không tìm thấy dữ liệu người dùng!";
                          }
                        } catch (e) {
                          // CODE FIX MỚI: Đảm bảo widget còn tồn tại mới hiển thị lỗi
                          if (context.mounted) {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
                          }
                        }
                      },
                      child: const Text("ĐĂNG NHẬP"),
                    ),
                  ),
                  // --- NÚT ĐĂNG KÝ MỚI THÊM ---
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/register'),
                    child: const Text("Chưa có tài khoản? Đăng ký ngay"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}