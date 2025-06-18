import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'input_birthday_screen.dart'; // ✅ ย้อนกลับไปหน้าระบุวันเกิด
import 'input_lifestyle_screen.dart';

class InputWeightHeightScreen extends StatefulWidget {
  @override
  _InputWeightHeightScreenState createState() => _InputWeightHeightScreenState();
}

class _InputWeightHeightScreenState extends State<InputWeightHeightScreen> {
  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  String gender = "";
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isSaving = false;

  bool isFilled() {
    return heightController.text.trim().isNotEmpty &&
        weightController.text.trim().isNotEmpty &&
        gender.isNotEmpty;
  }

  Future<void> _saveData() async {
    if (!isFilled()) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("กรุณากรอกข้อมูลให้ครบ!")));
      return;
    }

    setState(() => _isSaving = true);

    try {
      User? user = _auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("ไม่พบผู้ใช้ กรุณาล็อกอินใหม่!")));
        return;
      }

      await _firestore.collection("users").doc(user.uid).set({
        "height": heightController.text.trim(),
        "weight": weightController.text.trim(),
        "gender": gender
      }, SetOptions(merge: true));

      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => InputLifestyleScreen()));
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
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => InputBirthdayScreen())), // ✅ ย้อนกลับไปหน้าระบุวันเกิด
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
              Text("ระบุน้ำหนักและส่วนสูง", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue[900])),
              SizedBox(height: 10),
              _buildTextField(heightController, "ส่วนสูงของคุณ (ซม.)"),
              SizedBox(height: 15),
              _buildTextField(weightController, "น้ำหนักของคุณ (กก.)"),
              SizedBox(height: 20),
              _buildGenderSelection(), // ✅ ใช้เมธอดเลือกเพศ
              SizedBox(height: 20),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[400], 
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 100),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: _isSaving ? null : _saveData,
                child: _isSaving
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text("ถัดไป", style: TextStyle(fontSize: 18, color: Color.fromARGB(255, 47, 130, 174),)),
              ),
            ],
          ),
        ),
      ),
    );
  }
// Helper methods
  Widget _buildTextField(TextEditingController controller, String hintText) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(8), 
        border: Border.all(color: Colors.grey)
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          border: InputBorder.none, 
          hintText: hintText,
        ),
      ),
    );
  }

  Widget _buildGenderSelection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildGenderButton("ชาย", Colors.blue),
        SizedBox(width: 10),
        _buildGenderButton("หญิง", Colors.pink),
      ],
    );
  }

  Widget _buildGenderButton(String label, Color activeColor) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: gender == label ? activeColor : Colors.grey[300],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      onPressed: () => setState(() => gender = label),
      child: Text(label, style: TextStyle(color: gender == label ? Colors.white : Colors.black)),
    );
  }
}