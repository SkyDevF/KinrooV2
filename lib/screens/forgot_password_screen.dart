import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController emailController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String statusMessage = '';

  Future<void> _resetPassword() async {
    try {
      await _auth.sendPasswordResetEmail(email: emailController.text.trim());
      setState(() => statusMessage = "✅ ส่งลิงก์รีเซ็ตรหัสผ่านไปที่อีเมลแล้ว!");
    } catch (e) {
      setState(() => statusMessage = "❌ เกิดข้อผิดพลาด ลองอีกครั้ง");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // ✅ ป้องกัน UI ขยับเมื่อคีย์บอร์ดแสดงขึ้นมา
      backgroundColor: Colors.white,
      body: SingleChildScrollView( // ✅ ใช้เพื่อป้องกัน Overflow ของ Column
        child: Center(
          child: Container(
            padding: EdgeInsets.all(15),
            width: 350,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 5)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/icon/logo.png', width: 300, height: 200), // ✅ ใส่โลโก้
                SizedBox(height: 20),
                Text("ลืมรหัสผ่าน", style: TextStyle(fontSize: 25, color: Colors.blue[900])), // ✅ ข้อความในกล่อง
                SizedBox(height: 15),
                Text("ไม่ต้องกังวล คุณสามารถเปลี่ยนรหัสผ่านได้ง่ายๆด้วยการกรอกอีเมล แล้วคลิกลิ้งในอีเมลของคุณ", style: TextStyle(fontSize: 12, color: Colors.grey[900])),
                SizedBox(height: 50),

                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey)),
                  child: TextField(
                    controller: emailController,
                    decoration: InputDecoration(border: InputBorder.none, hintText: "อีเมลของคุณ"),
                  ),
                ),
                SizedBox(height: 15),

                statusMessage.isNotEmpty ? Text(statusMessage, style: TextStyle(color: Colors.red)) : Container(),
                SizedBox(height: 20),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 100),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: _resetPassword,
                  child: Text("ยืนยัน", style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
                SizedBox(height: 20),

                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LoginScreen())),
                  child: Text("มีบัญชีอยู่แล้ว? ล็อกอินเลย", style: TextStyle(fontSize: 16, color: Colors.blue[900])),
                ),
                SizedBox(height: 50), // ✅ เพิ่มระยะห่างด้านล่าง
              ],
            ),
          ),
        ),
      ),
    );
  }
}