import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'input_goal_screen.dart';
import 'input_lifestyle_screen.dart'; // ✅ ย้อนกลับไปหน้าระบุไลฟ์สไตล์

class InputHealthScreen extends StatefulWidget {
  const InputHealthScreen({super.key});

  @override
  _InputHealthScreenState createState() => _InputHealthScreenState();
}

class _InputHealthScreenState extends State<InputHealthScreen> {
  List<String> allergies = [];
  final List<String> options = ["ถั่ว", "ผลิตภัณฑ์จากนม", "กลูเตน", "อาหารทะเล", "ไข่", "อาหารที่แพ้อื่นๆ", "ไม่มีอาการแพ้"];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isSaving = false;

  void _toggleAllergy(String allergy) {
    setState(() {
      if (allergies.contains(allergy)) {
        allergies.remove(allergy);
      } else {
        allergies.add(allergy);
      }
    });
  }

  Future<void> _saveData() async {
    if (allergies.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("กรุณาเลือกอาการแพ้!")));
      return;
    }

    setState(() => _isSaving = true);

    try {
      User? user = _auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("ไม่พบผู้ใช้ กรุณาล็อกอินใหม่!")));
        return;
      }

      await _firestore.collection("users").doc(user.uid).set({"allergies": allergies}, SetOptions(merge: true));

      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => InputGoalScreen()));
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
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => InputLifestyleScreen())), // ✅ ย้อนกลับไปหน้าระบุไลฟ์สไตล์
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
              Text("เลือกอาการแพ้อาหาร", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue[900])),
              SizedBox(height: 10),
              Column(
                children: options.map((option) => _buildCheckboxTile(option)).toList(),
              ),
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

  Widget _buildCheckboxTile(String option) {
    return CheckboxListTile(
      title: Text(option, style: TextStyle(fontSize: 16)),
      value: allergies.contains(option),
      onChanged: (value) => _toggleAllergy(option),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), // ✅ ปรับเป็นสี่เหลี่ยมมน
      activeColor: Colors.blue,
    );
  }
}