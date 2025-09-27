import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String errorMessage = '';
  bool isLoading = false;

  Future<void> _signUp() async {
    if (passwordController.text != confirmPasswordController.text) {
      setState(() => errorMessage = "รหัสผ่านไม่ตรงกัน");
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // แสดงข้อความสำเร็จ
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '🎉 สร้างบัญชีสำเร็จ! กรุณาเข้าสู่ระบบ',
              style: TextStyle(fontSize: 16),
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // รอ 1 วินาทีแล้วไปหน้า Login
        await Future.delayed(const Duration(seconds: 1));

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = _getErrorMessage(e.toString());
          isLoading = false;
        });
      }
    }
  }

  String _getErrorMessage(String error) {
    if (error.contains('weak-password')) {
      return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
    } else if (error.contains('email-already-in-use')) {
      return 'อีเมลนี้ถูกใช้งานแล้ว';
    } else if (error.contains('invalid-email')) {
      return 'รูปแบบอีเมลไม่ถูกต้อง';
    } else {
      return 'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        // ✅ แก้ไขให้เลื่อนหน้าจอได้
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              const SizedBox(height: 120), // ✅ ปรับค่าความสูงตามที่ต้องการ
              const Text(
                "ยินดีต้อนรับ\nสร้างบัญชีเพื่อใช้งาน",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D47A1),
                ),
                textAlign: TextAlign.start,
              ),
              const SizedBox(height: 70),

              // ✅ ช่องกรอกอีเมล (แก้ไข overflow)
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
                  enabled: !isLoading,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: "กรอกอีเมลของคุณ",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // ✅ ช่องกรอกรหัสผ่าน (แก้ไข overflow)
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
                  enabled: !isLoading,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "กรอกรหัสผ่านของคุณ (อย่างน้อย 6 ตัวอักษร)",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // ✅ ช่องยืนยันรหัสผ่าน (แก้ไข overflow)
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
                  controller: confirmPasswordController,
                  enabled: !isLoading,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "ยืนยันรหัสผ่านของคุณ",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              if (errorMessage.isNotEmpty)
                Container(
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

              const SizedBox(height: 20),

              // ✅ ปุ่มสร้างบัญชี สีเทาเข้ม
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    vertical: 15,
                    horizontal: 120,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: isLoading ? null : _signUp,
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "สร้างบัญชี",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
              ),

              const SizedBox(height: 30),

              // ✅ ข้อความ "มีบัญชีอยู่แล้ว? ล็อกอินเลย"
              TextButton(
                onPressed: isLoading
                    ? null
                    : () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      ),
                child: Text(
                  "มีบัญชีอยู่แล้ว? ล็อกอินเลย",
                  style: TextStyle(
                    fontSize: 16,
                    color: isLoading ? Colors.grey : Colors.blue[900],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
