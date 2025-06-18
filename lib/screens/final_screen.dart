import 'package:flutter/material.dart';
import 'home_screen.dart';

class FinalScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("ยินดีต้อนรับสู่ Kinroo")),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("ขอบคุณที่ใช้ Kinroo! 🎉", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text("คุณสามารถกลับไปที่หน้าหลักเพื่อเริ่มต้นใช้งานแอปของคุณ", style: TextStyle(fontSize: 16)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen())),
              child: Text("กลับไปหน้าหลัก"),
            ),
          ],
        ),
      ),
    );
  }
}