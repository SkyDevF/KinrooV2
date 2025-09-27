import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../providers/auth_provider.dart';
import 'register_screen.dart';
import 'home_screen.dart';
import 'forgot_password_screen.dart';
import 'input_birthday_screen.dart';
import 'google_register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String errorMessage = '';
  bool _obscureText = true;
  bool _isLoggingIn = false;

  Future<void> _signIn() async {
    if (emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      setState(() => errorMessage = "กรุณากรอกอีเมลและรหัสผ่าน");
      return;
    }

    setState(() {
      _isLoggingIn = true;
      errorMessage = '';
    });

    try {
      final authService = ref.read(authServiceProvider);
      UserCredential userCredential = await authService
          .signInWithEmailAndPassword(
            emailController.text.trim(),
            passwordController.text.trim(),
          );

      User? user = userCredential.user;
      if (user == null) throw Exception("เข้าสู่ระบบไม่สำเร็จ");

      DocumentSnapshot userDoc = await authService.getUserDocument(user.uid);

      // แสดงข้อความสำเร็จ
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '🎉 เข้าสู่ระบบสำเร็จ! ยินดีต้อนรับ',
              style: TextStyle(fontSize: 16),
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // รอ 0.5 วินาทีแล้วไปหน้าถัดไป
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => userDoc.exists
                  ? const HomeScreen()
                  : const InputBirthdayScreen(),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = _getErrorMessage(e.toString());
          _isLoggingIn = false;
        });
      }
    }
  }

  String _getErrorMessage(String error) {
    if (error.contains('user-not-found')) {
      return 'ไม่พบบัญชีผู้ใช้นี้';
    } else if (error.contains('wrong-password')) {
      return 'รหัสผ่านไม่ถูกต้อง';
    } else if (error.contains('invalid-email')) {
      return 'รูปแบบอีเมลไม่ถูกต้อง';
    } else if (error.contains('user-disabled')) {
      return 'บัญชีนี้ถูกปิดการใช้งาน';
    } else if (error.contains('too-many-requests')) {
      return 'มีการพยายามเข้าสู่ระบบมากเกินไป กรุณาลองใหม่ภายหลัง';
    } else if (error.contains('invalid-credential')) {
      return 'อีเมลหรือรหัสผ่านไม่ถูกต้อง';
    } else {
      return 'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง';
    }
  }

  Future<void> _navigateToGoogleRegister() async {
    if (_isLoggingIn) return;

    // Navigate to Google registration screen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const GoogleRegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ ป้องกัน overflow เมื่อแสดงคีย์บอร์ด
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          // ✅ เพิ่ม physics เพื่อให้ scroll ได้เสมอ
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: ConstrainedBox(
            // ✅ ให้ content มีความสูงขั้นต่ำเท่ากับหน้าจอ
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom -
                  32,
            ),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ✅ ลด spacing เมื่อหน้าจอเล็ก
                  SizedBox(
                    height: MediaQuery.of(context).size.height < 700 ? 20 : 40,
                  ),

                  Text(
                    "ยินดีต้อนรับ\nล็อกอินบัญชีเพื่อใช้งาน",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.height < 700
                          ? 22
                          : 26,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0D47A1),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ช่องกรอกอีเมล
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromARGB(66, 255, 255, 255),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: emailController,
                      enabled: !_isLoggingIn,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: "กรอกอีเมลของคุณ",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ช่องกรอกรหัสผ่าน
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromARGB(66, 255, 255, 255),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: passwordController,
                      enabled: !_isLoggingIn,
                      obscureText: _obscureText,
                      decoration: InputDecoration(
                        labelText: "กรอกรหัสผ่านของคุณ",
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureText
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          color: Colors.grey,
                          tooltip: _obscureText
                              ? "เปิดการมองเห็นรหัสผ่าน"
                              : "ปิดการมองเห็นรหัสผ่าน",
                          onPressed: _isLoggingIn
                              ? null
                              : () => setState(
                                  () => _obscureText = !_obscureText,
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (errorMessage.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errorMessage,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _isLoggingIn
                          ? null
                          : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ForgotPasswordScreen(),
                              ),
                            ),
                      child: Text(
                        "ลืมรหัสผ่าน?",
                        style: TextStyle(
                          color: _isLoggingIn ? Colors.grey : Colors.blue[900],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ปุ่มเข้าสู่ระบบปกติ
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        vertical: 15,
                        horizontal: 80,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    onPressed: _isLoggingIn ? null : _signIn,
                    child: _isLoggingIn
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            "เข้าสู่ระบบ",
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                  ),

                  const SizedBox(height: 20),

                  // ขีดคั่น
                  Row(
                    children: [
                      const Expanded(child: Divider(thickness: 1)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "หรือ",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                      const Expanded(child: Divider(thickness: 1)),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ปุ่ม Google Sign In
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 24,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    onPressed: _isLoggingIn ? null : _navigateToGoogleRegister,
                    icon: Image.asset(
                      'assets/icon/google_logo.png',
                      height: 24,
                      width: 24,
                    ),
                    label: const Text(
                      "เข้าสู่ระบบด้วย Google",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextButton(
                    onPressed: _isLoggingIn
                        ? null
                        : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterScreen(),
                            ),
                          ),
                    child: Text(
                      "ไม่มีบัญชีผู้ใช้? สร้างเลย",
                      style: TextStyle(
                        fontSize: 16,
                        color: _isLoggingIn ? Colors.grey : Colors.blue[900],
                      ),
                    ),
                  ),

                  // ✅ เพิ่ม spacing ท้าย
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
