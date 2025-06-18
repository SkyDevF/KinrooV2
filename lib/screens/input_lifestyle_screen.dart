import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'input_health_screen.dart';
import 'input_weight_height_screen.dart'; // ✅ ย้อนกลับไปหน้าระบุน้ำหนักและส่วนสูง

class InputLifestyleScreen extends StatefulWidget {
  @override
  _InputLifestyleScreenState createState() => _InputLifestyleScreenState();
}

class _InputLifestyleScreenState extends State<InputLifestyleScreen> {
  String selectedLifestyle = "";
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isSaving = false; // ✅ ตรวจสอบสถานะการบันทึกข้อมูล

  Future<void> _saveData() async {
    if (selectedLifestyle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("กรุณาเลือกไลฟ์สไตล์!")));
      return;
    }

    setState(() => _isSaving = true); // ✅ แสดงสถานะกำลังบันทึกข้อมูล

    try {
      User? user = _auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("ไม่พบผู้ใช้ กรุณาล็อกอินใหม่!")));
        return;
      }

      await _firestore.collection("users").doc(user.uid).set({"lifestyle": selectedLifestyle}, SetOptions(merge: true));

      if (!mounted) return; // ✅ ป้องกันปัญหาหลังจาก state ถูก Dispose
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => InputHealthScreen()));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("เกิดข้อผิดพลาด กรุณาลองใหม่!")));
    } finally {
      setState(() => _isSaving = false); // ✅ ซ่อนสถานะการบันทึกข้อมูล
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 70, 51, 43), // ✅ พื้นหลัง
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 47, 130, 174), // ✅ สีแถบด้านบน
        centerTitle: true,
        title: Image.asset('assets/icon/logo.png', width: 150, height: 100), // ✅ โลโก้ตรงกลางแถบด้านบน
        leading: Container(
          margin: EdgeInsets.all(8),
          width: 50, height: 50,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)), // ✅ กล่องสีขาวรอบปุ่มย้อนกลับ
          child: IconButton(
            icon: Icon(Icons.arrow_back, size: 28, color: Colors.black),
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => InputWeightHeightScreen())), // ✅ ย้อนกลับไปหน้าระบุน้ำหนักและส่วนสูง
          ),
        ),
      ),
      body: Center(
        child: Container(
          padding: EdgeInsets.all(20),
          width: 350,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 5)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("เลือกไลฟ์สไตล์ของคุณ", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue[900])),
              SizedBox(height: 10),
              _buildLifestyleButton("นักกีฬา"),
              _buildLifestyleButton("แอคทีฟสุดๆ"),
              _buildLifestyleButton("แอคทีฟกว่าคนทั่วไป"),
              _buildLifestyleButton("แอคทีฟอยู่บ้าง"),
              _buildLifestyleButton("ไม่แอคทีฟเลย"),
              SizedBox(height: 20),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 47, 130, 174), 
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 100),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), // ✅ ปุ่มถัดไปเป็นสี่เหลี่ยมมน
                ),
                onPressed: _isSaving ? null : _saveData,
                child: _isSaving
                    ? CircularProgressIndicator(color: Colors.white) // ✅ แสดงโหลดข้อมูลขณะบันทึก
                    : Text("ถัดไป", style: TextStyle(fontSize: 18, color: Color.fromARGB(255, 255, 255, 255),)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLifestyleButton(String label) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: selectedLifestyle == label ? Colors.blue : Colors.grey[300],
          padding: EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), // ✅ ปุ่มเลือกไลฟ์สไตล์เป็นสี่เหลี่ยมมน
        ),
        onPressed: () => setState(() => selectedLifestyle = label),
        child: Text(label, style: TextStyle(color: selectedLifestyle == label ? Colors.white : Colors.black)),
      ),
    );
  }
}