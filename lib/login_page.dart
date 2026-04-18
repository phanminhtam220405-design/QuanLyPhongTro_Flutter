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
          gradient: LinearGradient(colors: [Color(0xFF1976D2), Color(0xFF0D47A1)]),
        ),
        child: Center(
          child: Card(
            margin: const EdgeInsets.all(25),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(25),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.account_circle, size: 80, color: Color(0xFF1976D2)),
                  const Text("QUẢN LÝ TRỌ HUIT", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  TextField(controller: emailController, decoration: const InputDecoration(labelText: "Email", border: OutlineInputBorder())),
                  const SizedBox(height: 10),
                  TextField(controller: passwordController, obscureText: true, decoration: const InputDecoration(labelText: "Mật khẩu", border: OutlineInputBorder())),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1976D2)),
                      onPressed: () async {
                        try {
                          UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
                            email: emailController.text.trim(), password: passwordController.text.trim(),
                          );
                          DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).get();
                          if (userDoc.exists && context.mounted) {
                            String role = userDoc['role'] ?? 'user';
                            if (role == 'admin') {
                              Navigator.pushReplacementNamed(context, '/dashboard');
                            } else {
                              Navigator.pushReplacementNamed(context, '/user_home');
                            }
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
                        }
                      },
                      child: const Text("ĐĂNG NHẬP", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  // --- TRẢ LẠI NÚT ĐĂNG KÝ CỦA BẠN Ở ĐÂY ---
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