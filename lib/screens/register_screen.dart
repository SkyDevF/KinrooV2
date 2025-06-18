import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String errorMessage = '';

  Future<void> _signUp() async {
    if (passwordController.text != confirmPasswordController.text) {
      setState(() => errorMessage = "รหัสผ่านไม่ตรงกัน");
      return;
    }
    try {
      await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen()),
      );
    } catch (e) {
      setState(() => errorMessage = "สมัครสมาชิกไม่สำเร็จ");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        // ✅ แก้ไขให้เลื่อนหน้าจอได้
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              SizedBox(height: 120), // ✅ ปรับค่าความสูงตามที่ต้องการ
              Text(
                "ยินดีต้อนรับ\nสร้างบัญชีเพื่อใช้งาน",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900],
                ),
                textAlign: TextAlign.start,
              ),
              SizedBox(height: 70),

              // ✅ ช่องกรอกอีเมล (แก้ไข overflow)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromARGB(66, 255, 255, 255),
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: "กรอกอีเมลของคุณ",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              SizedBox(height: 15),

              // ✅ ช่องกรอกรหัสผ่าน (แก้ไข overflow)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromARGB(66, 255, 255, 255),
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "กรอกรหัสผ่านของคุณ",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              SizedBox(height: 15),

              // ✅ ช่องยืนยันรหัสผ่าน (แก้ไข overflow)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromARGB(66, 255, 255, 255),
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "ยืนยันรหัสผ่านของคุณ",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              SizedBox(height: 20),

              if (errorMessage.isNotEmpty)
                Text(errorMessage, style: TextStyle(color: Colors.red)),

              SizedBox(height: 20),

              // ✅ ปุ่มสร้างบัญชี สีเทาเข้ม
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 120),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      15,
                    ), // ทำเป็นกล่องสี่เหลี่ยมผืนผ้า
                  ),
                ),
                onPressed: _signUp,
                child: Text(
                  "สร้างบัญชี",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),

              SizedBox(height: 30),

              // ✅ ข้อความ "มีบัญชีอยู่แล้ว? ล็อกอินเลย"
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => LoginScreen()),
                ),
                child: Text(
                  "มีบัญชีอยู่แล้ว? ล็อกอินเลย",
                  style: TextStyle(fontSize: 16, color: Colors.blue[900]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
