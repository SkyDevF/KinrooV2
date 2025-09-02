import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'input_weight_height_screen.dart';

class InputBirthdayScreen extends StatefulWidget {
  const InputBirthdayScreen({super.key});

  @override
  _InputBirthdayScreenState createState() => _InputBirthdayScreenState();
}

class _InputBirthdayScreenState extends State<InputBirthdayScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isSaving = false; // ✅ ตรวจสอบสถานะการบันทึกข้อมูล

  bool isFilled() {
    return nameController.text.trim().isNotEmpty && ageController.text.trim().isNotEmpty;
  }

  Future<void> _saveData() async {
    if (!isFilled()) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("กรุณากรอกข้อมูลให้ครบ!")));
      return;
    }

    setState(() => _isSaving = true); // ✅ แสดงสถานะกำลังบันทึกข้อมูล

    try {
      User? user = _auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("ไม่พบผู้ใช้ กรุณาล็อกอินใหม่!")));
        return;
      }

      await _firestore.collection("users").doc(user.uid).set({
        "name": nameController.text.trim(),
        "age": ageController.text.trim(),
      }, SetOptions(merge: true));

      if (!mounted) return; // ✅ ป้องกันปัญหาหลังจาก state ถูก Dispose
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => InputWeightHeightScreen()));
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
        title: Image.asset('assets/icon/logo.png', width: 150, height: 100),
        leading: Container(
          margin: EdgeInsets.all(8),
          width: 50, height: 50,
          decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
          child: IconButton(
            icon: Icon(Icons.arrow_back, size: 28, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: Center(
        child: Container(
          padding: EdgeInsets.all(20),
          width: 300,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 5)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("ระบุวันเกิดของคุณ", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue[900])),
              SizedBox(height: 8),
              Text(
                "ระบุอายุของคุณเพื่อปรับค่าทางโภชนาการให้เหมาะสมตามความต้องการของคุณ",
                textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              SizedBox(height: 20),

              // ✅ ช่องกรอกชื่อ
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey)),
                child: TextField(
                  controller: nameController,
                  decoration: InputDecoration(border: InputBorder.none, hintText: "ระบุชื่อของคุณ"),
                ),
              ),
              SizedBox(height: 15),

              // ✅ ช่องกรอกอายุ
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey)),
                child: TextField(
                  controller: ageController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(border: InputBorder.none, hintText: "อายุของคุณคือ"),
                ),
              ),
              SizedBox(height: 20),

              // ✅ ปุ่มถัดไปสีเทาอ่อน พร้อมแสดงสถานะกำลังบันทึก
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Color.fromARGB(255, 47, 130, 174), padding: EdgeInsets.symmetric(vertical: 12, horizontal: 100)),
                onPressed: _isSaving ? null : _saveData,
                child: _isSaving
                    ? CircularProgressIndicator(color: Colors.white) // ✅ แสดงโหลดข้อมูลเมื่อกำลังบันทึก
                    : Text("ถัดไป", style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}