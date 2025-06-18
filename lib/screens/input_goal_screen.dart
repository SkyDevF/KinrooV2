import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'summary_screen.dart';
import 'input_health_screen.dart'; // ✅ ย้อนกลับไปหน้าระบุสุขภาพ

class InputGoalScreen extends StatefulWidget {
  @override
  _InputGoalScreenState createState() => _InputGoalScreenState();
}

class _InputGoalScreenState extends State<InputGoalScreen> {
  final TextEditingController targetWeightController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isSaving = false;

  bool isFilled() {
    return targetWeightController.text.trim().isNotEmpty;
  }

  Future<void> _saveData() async {
    if (!isFilled()) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("กรุณากรอกน้ำหนักเป้าหมาย!")));
      return;
    }

    setState(() => _isSaving = true);

    try {
      User? user = _auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("ไม่พบผู้ใช้ กรุณาล็อกอินใหม่!")));
        return;
      }

      await _firestore.collection("users").doc(user.uid).set({"targetWeight": targetWeightController.text.trim()}, SetOptions(merge: true));

      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => SummaryScreen()));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("เกิดข้อผิดพลาด กรุณาลองใหม่!")));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 70, 51, 43),
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 47, 130, 174),
        centerTitle: true,
        title: Image.asset('assets/icon/logo.png', width: 150, height: 100),
        leading: Container(
          margin: EdgeInsets.all(8),
          width: 50, height: 50,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)), // ✅ กล่องสีขาวรอบปุ่มย้อนกลับ
          child: IconButton(
            icon: Icon(Icons.arrow_back, size: 28, color: Colors.black),
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => InputHealthScreen())), // ✅ ย้อนกลับไปหน้าระบุสุขภาพ
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
              Text("ตั้งน้ำหนักเป้าหมายของคุณ", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue[900])),
              SizedBox(height: 10),

              _buildTextField(targetWeightController, "น้ำหนักเป้าหมาย (กก.)"),
              SizedBox(height: 20),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 47, 130, 174),
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 100),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: _isSaving ? null : _saveData,
                child: _isSaving
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text("ถัดไป", style: TextStyle(fontSize: 18, color: const Color.fromARGB(255, 255, 255, 255))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hintText) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey)),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(border: InputBorder.none, hintText: hintText),
      ),
    );
  }
}