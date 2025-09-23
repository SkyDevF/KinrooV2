import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'input_birthday_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ✅ ตั้งค่าภาพพื้นหลัง
          Positioned.fill(
            child: Image.asset('assets/icon/welcome.png', fit: BoxFit.cover),
          ),

          // ✅ ปุ่มและข้อความ
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 350), // ✅ เว้นระยะด้านบนให้พอดีกับ UI

                _buildButton(context, "ล็อกอิน", Colors.black, LoginScreen()),
                SizedBox(height: 15),
                _buildButton(
                  context,
                  "สร้างบัญชี",
                  Colors.white,
                  RegisterScreen(),
                  textColor: Colors.black,
                ),
                SizedBox(height: 25),

                _buildTrialAccount(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(
    BuildContext context,
    String label,
    Color color,
    Widget screen, {
    Color textColor = Colors.white,
  }) {
    return SizedBox(
      width: 350,
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
        child: Text(label, style: TextStyle(fontSize: 18, color: textColor)),
      ),
    );
  }

  Widget _buildTrialAccount(BuildContext context) {
    return GestureDetector(
      onTap: () => _signInAnonymously(context),
      child: Column(
        children: [
          Text(
            "กดใช้งาน บัญชีทดลอง",
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
          SizedBox(height: 3),
          Container(width: 200, height: 2, color: Colors.white),
        ],
      ),
    );
  }

  // ✅ ฟังก์ชันสำหรับล็อกอินแบบไม่ระบุตัวตน
  Future<void> _signInAnonymously(BuildContext context) async {
    try {
      print("🔄 เริ่มต้นล็อกอินแบบไม่ระบุตัวตน...");

      // แสดง loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
            Center(child: CircularProgressIndicator(color: Colors.white)),
      );

      // ล็อกอินแบบไม่ระบุตัวตน
      UserCredential userCredential = await FirebaseAuth.instance
          .signInAnonymously();
      print("✅ ล็อกอินสำเร็จ: ${userCredential.user?.uid}");

      // ตรวจสอบว่า context ยังใช้ได้หรือไม่
      if (!context.mounted) return;

      // ปิด loading dialog
      Navigator.pop(context);

      // ไปหน้าใส่ข้อมูลวันเกิด
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => InputBirthdayScreen()),
      );
    } catch (e) {
      print("❌ ข้อผิดพลาดในการล็อกอิน: $e");

      // ตรวจสอบว่า context ยังใช้ได้หรือไม่
      if (!context.mounted) return;

      // ปิด loading dialog
      Navigator.pop(context);

      // แสดงข้อผิดพลาดที่ละเอียดขึ้น
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("เกิดข้อผิดพลาด: ${e.toString()}"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }
}
