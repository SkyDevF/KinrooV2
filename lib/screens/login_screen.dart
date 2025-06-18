import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'register_screen.dart';
import 'home_screen.dart';
import 'forgot_password_screen.dart';
import 'input_birthday_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String errorMessage = '';
  bool _obscureText = true; // ✅ เพิ่มตัวแปรสำหรับเปิด-ปิดรหัสผ่าน
  bool _isLoggingIn = false; // ✅ ตรวจสอบสถานะการเข้าสู่ระบบ

  Future<void> _signIn() async {
    if (emailController.text.trim().isEmpty || passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("กรุณากรอกอีเมลและรหัสผ่าน")));
      return;
    }

    setState(() => _isLoggingIn = true); // ✅ แสดงสถานะกำลังเข้าสู่ระบบ

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      User? user = userCredential.user;
      if (user == null) throw Exception("เข้าสู่ระบบไม่สำเร็จ");

      DocumentSnapshot userDoc = await _firestore.collection("users").doc(user.uid).get();

      if (!mounted) return; // ✅ ป้องกันการทำงานหลังจาก State ถูก Dispose
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => userDoc.exists ? HomeScreen() : InputBirthdayScreen()));
    } catch (e) {
      setState(() => errorMessage = "เข้าสู่ระบบไม่สำเร็จ: ${e.toString()}");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
    } finally {
      setState(() => _isLoggingIn = false); // ✅ ซ่อนสถานะการเข้าสู่ระบบ
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("ยินดีต้อนรับ\nล็อกอินบัญชีเพื่อใช้งาน", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.blue[900])),
            SizedBox(height: 20),

            TextField(controller: emailController, decoration: InputDecoration(labelText: "กรอกอีเมลของคุณ", border: OutlineInputBorder(), prefixIcon: Icon(Icons.email))),
            SizedBox(height: 15),

            TextField(
              controller: passwordController,
              obscureText: _obscureText,
              decoration: InputDecoration(
                labelText: "กรอกรหัสผ่านของคุณ",
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility),
                  color: Colors.grey,
                  tooltip: _obscureText ? "เปิดการมองเห็นรหัสผ่าน" : "ปิดการมองเห็นรหัสผ่าน",
                  onPressed: () => setState(() => _obscureText = !_obscureText),
                ),
              ),
            ),
            SizedBox(height: 10),

            if (errorMessage.isNotEmpty) Text(errorMessage, style: TextStyle(color: Colors.red)),
            SizedBox(height: 10),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ForgotPasswordScreen())),
                child: Text("ลืมรหัสผ่าน?", style: TextStyle(color: Colors.blue[900])),
              ),
            ),
            SizedBox(height: 20),

            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black, padding: EdgeInsets.symmetric(vertical: 15, horizontal: 120), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
              onPressed: _isLoggingIn ? null : _signIn,
              child: _isLoggingIn
                  ? CircularProgressIndicator(color: Colors.blue[900]) // ✅ แสดงโหลดข้อมูลขณะล็อกอิน
                  : Text("เข้าสู่ระบบ", style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
            SizedBox(height: 20),

            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RegisterScreen())),
              child: Text("ไม่มีบัญชีผู้ใช้? สร้างเลย", style: TextStyle(fontSize: 16, color: Colors.blue[900])),
            ),
          ],
        ),
      ),
    );
  }
}