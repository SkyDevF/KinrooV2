import 'package:flutter/material.dart';
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
                _buildButton(context, "สร้างบัญชี", Colors.white, RegisterScreen(), textColor: Colors.black),
                SizedBox(height: 25),

                _buildTrialAccount(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(BuildContext context, String label, Color color, Widget screen, {Color textColor = Colors.white}) {
    return SizedBox(
      width: 350,
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
        child: Text(label, style: TextStyle(fontSize: 18, color: textColor)),
      ),
    );
  }

  Widget _buildTrialAccount(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => InputBirthdayScreen())),
      child: Column(
        children: [
          Text("กดใช้งาน บัญชีทดลอง", style: TextStyle(fontSize: 16, color: Colors.white)),
          SizedBox(height: 3),
          Container(width: 200, height: 2, color: Colors.white),
        ],
      ),
    );
  }
}