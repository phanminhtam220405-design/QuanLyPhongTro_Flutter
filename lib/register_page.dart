import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterPage extends StatelessWidget {
  final TextEditingController nameController = TextEditingController();

  final TextEditingController emailController = TextEditingController();

  final TextEditingController passwordController = TextEditingController();

  RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),

          child: Column(
            children: [
              const SizedBox(height: 10),

              Container(
                width: 110,
                height: 110,

                decoration: BoxDecoration(
                  color: const Color(0xFF1976D2).withOpacity(0.1),

                  shape: BoxShape.circle,
                ),

                child: const Icon(
                  Icons.person_add_alt_1_rounded,
                  size: 60,
                  color: Color(0xFF1976D2),
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                "Tạo tài khoản mới",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              const Text(
                "Đăng ký để sử dụng hệ thống quản lý",
                style: TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 35),

              _modernInput(
                controller: nameController,
                label: "Họ và tên",
                hint: "Nhập họ tên",
                icon: Icons.person_outline,
              ),

              const SizedBox(height: 18),

              _modernInput(
                controller: emailController,
                label: "Email",
                hint: "Nhập email",
                icon: Icons.email_outlined,
              ),

              const SizedBox(height: 18),

              _modernInput(
                controller: passwordController,
                label: "Mật khẩu",
                hint: "Tối thiểu 6 ký tự",
                icon: Icons.lock_outline,
                isPass: true,
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 58,

                child: ElevatedButton.icon(
                  icon: const Icon(Icons.app_registration, color: Colors.white),

                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),

                  onPressed: () async {
                    try {
                      UserCredential userCredential = await FirebaseAuth
                          .instance
                          .createUserWithEmailAndPassword(
                            email: emailController.text.trim(),
                            password: passwordController.text.trim(),
                          );

                      await userCredential.user?.updateDisplayName(
                        nameController.text.trim(),
                      );

                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(userCredential.user!.uid)
                          .set({
                            'uid': userCredential.user!.uid,
                            'name': nameController.text.trim(),
                            'email': emailController.text.trim(),
                            'role': 'user',
                            'house_id': '',
                            'createdAt': DateTime.now(),
                          });

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: Colors.green,

                            content: Text("Đăng ký thành công"),
                          ),
                        );

                        Navigator.pop(context);
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: Colors.red,

                          content: Text("Lỗi đăng ký: $e"),
                        ),
                      );
                    }
                  },

                  label: const Text(
                    "ĐĂNG KÝ NGAY",

                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modernInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPass = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(18),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: TextField(
        controller: controller,
        obscureText: isPass,

        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFF1976D2)),

          labelText: label,
          hintText: hint,

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),

          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }
}
