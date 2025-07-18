import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'welcome_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String username = "กำลังโหลด...";
  String email = "กำลังโหลด...";
  double weight = 0.0;
  double height = 0.0;
  double targetWeight = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  void _fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser; // ✅ ดึงข้อมูลผู้ใช้
    if (user == null) return;

    await user.reload(); // ✅ รีเฟรชข้อมูลบัญชี
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (userDoc.exists) {
      setState(() {
        username = userDoc.get('name') ?? "ไม่พบข้อมูล";
        email = user.email ?? "ไม่มีอีเมล";
        weight = double.tryParse(userDoc.get('weight').toString()) ?? 0.0;
        height = double.tryParse(userDoc.get('height').toString()) ?? 0.0;
        targetWeight =
            double.tryParse(userDoc.get('targetWeight').toString()) ?? 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 47, 130, 174),
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 70, 51, 43),
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey),
            ),
            child: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: Color.fromARGB(255, 70, 51, 43),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Image.asset('assets/icon/logo.png', width: 150, height: 100),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/icon/sum.png',
              width: 200,
              height: 200,
              fit: BoxFit.cover,
            ), // ✅ ใส่รูปตรงกลาง
            SizedBox(height: 20),

            Text(
              username,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.brown[800],
              ),
            ),
            Text(
              email,
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ), // ✅ เพิ่มอีเมลใต้ชื่อ
            SizedBox(height: 30),

            Container(
              padding: EdgeInsets.all(20),
              width: 300,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 5)],
              ),
              child: Column(
                children: [
                  Text(
                    "น้ำหนัก: ${weight.toStringAsFixed(1)} กก.",
                    style: TextStyle(fontSize: 18),
                  ),
                  Text(
                    "ส่วนสูง: ${height.toStringAsFixed(1)} ซม.",
                    style: TextStyle(fontSize: 18),
                  ),
                  Text(
                    "เป้าหมายน้ำหนัก: ${targetWeight.toStringAsFixed(1)} กก.",
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
            SizedBox(height: 40),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 70, 51, 43),
              ),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => EditProfileScreen()),
                );
                if (result == true) {
                  _fetchUserData(); // รีเฟรชข้อมูลหลังแก้ไข
                }
              },
              child: Text(
                "แก้ไขข้อมูลส่วนตัว",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
            SizedBox(height: 40),

            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
              onPressed: () async {
                await FirebaseAuth.instance.signOut(); // ✅ ออกจากระบบ
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => WelcomeScreen()),
                );
              },
              child: Text(
                "ล็อกเอาท์",
                style: TextStyle(
                  color: Color.fromARGB(255, 70, 51, 43),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
