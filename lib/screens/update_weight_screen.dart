import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';

class UpdateWeightScreen extends StatefulWidget {
  @override
  _UpdateWeightScreenState createState() => _UpdateWeightScreenState();
}

class _UpdateWeightScreenState extends State<UpdateWeightScreen> {
  final TextEditingController weightController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isFilled() {
    return weightController.text.isNotEmpty;
  }

  Future<void> _updateWeight() async {
    User? user = _auth.currentUser;
    if (user != null && isFilled()) {
      await _firestore.collection("users").doc(user.uid).set({
        "weight": weightController.text.trim()
      }, SetOptions(merge: true));

      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen()));
    }
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Color(0xFF3E2723), // ✅ พื้นหลังน้ำตาลเข้ม
    appBar: AppBar(
      title: Text("อัปเดตน้ำหนัก"),
      backgroundColor: Color(0xFF1E88E5), // ✅ แถบสีฟ้าเข้ม
    ),
    body: Center( // ✅ ใช้ Center เพื่อให้เนื้อหาตรงกลาง
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // ✅ จัดให้อยู่กลางแนวตั้ง
          crossAxisAlignment: CrossAxisAlignment.center, 
          children: [
            Container(
              width: 300, // ✅ กำหนดขนาดให้สมดุล
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15), // ✅ ขอบมน
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
              ),
              child: TextField(
                controller: weightController,
                decoration: InputDecoration(
                  labelText: "น้ำหนักใหม่ (กก.)",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) => setState(() {}),
              ),
            ),
            SizedBox(height: 20),
            Container(
              width: 300, // ✅ ขนาดเท่าช่องกรอก
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF1E88E5), Color(0xFF1565C0)]),
                borderRadius: BorderRadius.circular(15),
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  padding: EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: isFilled() ? _updateWeight : null,
                child: Text("ยืนยัน", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
  