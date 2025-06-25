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
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      body: Center( // ✅ ใช้ Center เพื่อจัดให้อยู่กึ่งกลางหน้าจอ
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 40), // ✅ เพิ่ม padding รอบๆ
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - 80, // ✅ ให้ความสูงขั้นต่ำเท่ากับหน้าจอ
            ),
            child: IntrinsicHeight( // ✅ ใช้เพื่อให้ Column ขยายตามเนื้อหา
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, // ✅ จัดให้อยู่กึ่งกลางในแนวตั้ง
                crossAxisAlignment: CrossAxisAlignment.center, // ✅ จัดให้อยู่กึ่งกลางในแนวนอน
                children: [
                  Container(
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
                        Image.asset('assets/icon/logo.png', width: 300, height: 200),
                        SizedBox(height: 20),
                        Text(
                          "ลืมรหัสผ่าน", 
                          style: TextStyle(fontSize: 25, color: Colors.blue[900])
                        ),
                        SizedBox(height: 15),
                        Text(
                          "ไม่ต้องกังวล คุณสามารถเปลี่ยนรหัสผ่านได้ง่ายๆด้วยการกรอกอีเมล แล้วคลิกลิ้งในอีเมลของคุณ", 
                          style: TextStyle(fontSize: 12, color: Colors.grey[900]),
                          textAlign: TextAlign.center, // ✅ จัดข้อความให้อยู่กึ่งกลาง
                        ),
                        SizedBox(height: 50),

                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8), 
                            border: Border.all(color: Colors.grey)
                          ),
                          child: TextField(
                            controller: emailController,
                            decoration: InputDecoration(
                              border: InputBorder.none, 
                              hintText: "อีเมลของคุณ"
                            ),
                          ),
                        ),
                        SizedBox(height: 15),

                        statusMessage.isNotEmpty 
                          ? Text(
                              statusMessage, 
                              style: TextStyle(color: Colors.red),
                              textAlign: TextAlign.center, // ✅ จัดข้อความให้อยู่กึ่งกลาง
                            )
                          : Container(),
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
                          onPressed: () => Navigator.push(
                            context, 
                            MaterialPageRoute(builder: (_) => LoginScreen())
                          ),
                          child: Text(
                            "มีบัญชีอยู่แล้ว? ล็อกอินเลย", 
                            style: TextStyle(fontSize: 16, color: Colors.blue[900])
                          ),
                        ),
                        SizedBox(height: 50),
                      ],
                    ),
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