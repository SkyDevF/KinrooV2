import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'register_screen.dart';
import 'home_screen.dart';
import 'forgot_password_screen.dart';
import 'input_birthday_screen.dart';
import 'google_register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String errorMessage = '';
  bool _obscureText = true;
  bool _isLoggingIn = false;

  Future<void> _signIn() async {
    if (emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("กรุณากรอกอีเมลและรหัสผ่าน")));
      return;
    }

    setState(() => _isLoggingIn = true);

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      User? user = userCredential.user;
      if (user == null) throw Exception("เข้าสู่ระบบไม่สำเร็จ");

      DocumentSnapshot userDoc = await _firestore
          .collection("users")
          .doc(user.uid)
          .get();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => userDoc.exists ? HomeScreen() : InputBirthdayScreen(),
        ),
      );
    } catch (e) {
      setState(() => errorMessage = "เข้าสู่ระบบไม่สำเร็จ: ${e.toString()}");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    } finally {
      setState(() => _isLoggingIn = false);
    }
  }

  Future<void> _navigateToGoogleRegister() async {
    // Navigate to Google registration screen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GoogleRegisterScreen()),
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
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                      color: Colors.blue[900],
                    ),
                  ),
                  SizedBox(height: 24),

                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: "กรอกอีเมลของคุณ",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),

                  TextField(
                    controller: passwordController,
                    obscureText: _obscureText,
                    decoration: InputDecoration(
                      labelText: "กรอกรหัสผ่านของคุณ",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
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
                        onPressed: () =>
                            setState(() => _obscureText = !_obscureText),
                      ),
                    ),
                  ),
                  SizedBox(height: 8),

                  if (errorMessage.isNotEmpty) ...[
                    Text(
                      errorMessage,
                      style: TextStyle(color: Colors.red, fontSize: 14),
                    ),
                    SizedBox(height: 8),
                  ],

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ForgotPasswordScreen(),
                        ),
                      ),
                      child: Text(
                        "ลืมรหัสผ่าน?",
                        style: TextStyle(color: Colors.blue[900]),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),

                  // ปุ่มเข้าสู่ระบบปกติ
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(
                        vertical: 15,
                        horizontal: 80,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      minimumSize: Size(double.infinity, 50),
                    ),
                    onPressed: _isLoggingIn ? null : _signIn,
                    child: _isLoggingIn
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            "เข้าสู่ระบบ",
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                  ),

                  SizedBox(height: 20),

                  // ขีดคั่น
                  Row(
                    children: [
                      Expanded(child: Divider(thickness: 1)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "หรือ",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                      Expanded(child: Divider(thickness: 1)),
                    ],
                  ),

                  SizedBox(height: 20),

                  // ปุ่ม Google Sign In
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      padding: EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 24,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      minimumSize: Size(double.infinity, 50),
                    ),
                    onPressed: _navigateToGoogleRegister,
                    icon: Image.asset(
                      'assets/icon/google_logo.png', // ต้องเพิ่มไฟล์ logo
                      height: 24,
                      width: 24,
                    ),
                    label: Text(
                      "เข้าสู่ระบบด้วย Google",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),

                  SizedBox(height: 16),

                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => RegisterScreen()),
                    ),
                    child: Text(
                      "ไม่มีบัญชีผู้ใช้? สร้างเลย",
                      style: TextStyle(fontSize: 16, color: Colors.blue[900]),
                    ),
                  ),

                  // ✅ เพิ่ม spacing ท้าย
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
