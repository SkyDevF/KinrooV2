import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';
import 'input_goal_screen.dart'; // ✅ ย้อนกลับไปหน้าระบุเป้าหมาย

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  _SummaryScreenState createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String targetWeight = "กำลังโหลด...";
  int recommendedCalories = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> saveDailyCalories() async {
    User? user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection("users").doc(user.uid).set({
        "daily_calories": recommendedCalories, // ✅ บันทึกค่าที่คำนวณไว้
        "last_updated":
            FieldValue.serverTimestamp(), // ✅ บันทึกเวลาที่อัปเดตล่าสุด
      }, SetOptions(merge: true));
      print("✅ บันทึกแคลอรี่ต่อวันสำเร็จ!");
    }
  }

  Future<void> _loadData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await _firestore
          .collection("users")
          .doc(user.uid)
          .get();
      if (userDoc.exists && userDoc.data() != null) {
        setState(() {
          targetWeight = userDoc.get("targetWeight") ?? "ยังไม่ได้ตั้งค่า";
          recommendedCalories = _calculateCalories(
            double.tryParse(targetWeight) ?? 0.0,
          );
        });
      }
    }
  }

  int _calculateCalories(double weight) {
    if (weight == 0.0) return 2000;
    return (weight * 30).toInt();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset:
          false, // ✅ ป้องกัน UI ขยับเมื่อคีย์บอร์ดแสดงขึ้นมา
      backgroundColor: Color.fromARGB(255, 70, 51, 43),
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 47, 130, 174),
        centerTitle: true,
        title: Image.asset('assets/icon/logo.png', width: 150, height: 100),
        leading: Container(
          margin: EdgeInsets.all(8),
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back, size: 28, color: Colors.black),
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => InputGoalScreen()),
            ),
          ),
        ),
      ),
      body: Center(
        // ✅ จัดให้อยู่กึ่งกลางหน้าจอ
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
            mainAxisAlignment:
                MainAxisAlignment.center, // ✅ จัดตำแหน่งให้อยู่ตรงกลางในกล่อง
            children: [
              Image.asset(
                'assets/icon/sum.png',
                width: 200,
                height: 250,
                fit: BoxFit.cover,
              ),
              SizedBox(height: 10),

              Text(
                "นี่คือเป้าหมายของคุณ",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900],
                ),
              ),
              SizedBox(height: 10),

              Text(
                "น้ำหนักเป้าหมายของคุณคือ",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 62, 62, 62),
                ),
              ),
              SizedBox(height: 1),
              Text(
                "$targetWeight กก.",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900],
                ),
              ),
              Text(
                "แคลอรี่ที่เหมาะสมต่อวันคือ",
                style: TextStyle(
                  fontSize: 10,
                  color: const Color.fromARGB(255, 47, 47, 47),
                ),
              ),
              Text(
                "$recommendedCalories kcal",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900],
                ),
              ),
              SizedBox(height: 20),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[900],
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: () {
                  saveDailyCalories(); // ✅ บันทึกข้อมูลลง Firebase
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => HomeScreen()),
                  );
                },
                child: Text(
                  "บันทึกข้อมูล",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
