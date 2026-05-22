
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatelessWidget {
  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),

          child: Column(
            children: [
              const SizedBox(height: 40),

              // LOGO
              Container(
                width: 120,
                height: 120,

                decoration: BoxDecoration(
                  color: const Color(0xFF1976D2)
                      .withOpacity(0.1),

                  shape: BoxShape.circle,
                ),

                child: const Icon(
                  Icons.home_work_rounded,
                  size: 65,
                  color: Color(0xFF1976D2),
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                "Quản lý phòng trọ",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                "Đăng nhập để tiếp tục sử dụng hệ thống",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 40),

              // FORM
              _modernInput(
                controller: emailController,
                label: "Email",
                hint: "Nhập email",
                icon: Icons.email_outlined,
              ),

              const SizedBox(height: 20),

              _modernInput(
                controller: passwordController,
                label: "Mật khẩu",
                hint: "Nhập mật khẩu",
                icon: Icons.lock_outline,
                isPass: true,
              ),

              const SizedBox(height: 30),

              // BUTTON LOGIN
              SizedBox(
                width: double.infinity,
                height: 58,

                child: ElevatedButton.icon(
                  icon: const Icon(
                    Icons.login,
                    color: Colors.white,
                  ),

                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF1976D2),

                    elevation: 2,

                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(18),
                    ),
                  ),

                  onPressed: () async {
                    try {
                      UserCredential userCredential =
                          await FirebaseAuth.instance
                              .signInWithEmailAndPassword(
                        email: emailController.text.trim(),
                        password:
                            passwordController.text.trim(),
                      );

                      DocumentSnapshot userDoc =
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(userCredential.user!.uid)
                              .get();

                      if (userDoc.exists &&
                          context.mounted) {
                        String role =
                            userDoc['role'] ?? 'user';

                        if (role == 'admin') {
                          Navigator.pushReplacementNamed(
                            context,
                            '/dashboard',
                          );
                        } else {
                          Navigator.pushReplacementNamed(
                            context,
                            '/user_home',
                          );
                        }
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        SnackBar(
                          backgroundColor: Colors.red,

                          content: Text(
                            "Đăng nhập thất bại: $e",
                          ),
                        ),
                      );
                    }
                  },

                  label: const Text(
                    "ĐĂNG NHẬP",

                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              TextButton(
                onPressed: () =>
                    Navigator.pushNamed(
                        context, '/register'),

                child: const Text(
                  "Chưa có tài khoản? Đăng ký ngay",
                  style: TextStyle(
                    color: Color(0xFF1976D2),
                    fontWeight: FontWeight.bold,
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
          prefixIcon: Icon(
            icon,
            color: const Color(0xFF1976D2),
          ),

          labelText: label,
          hintText: hint,

          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),

          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }
}
