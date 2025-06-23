import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/intro_screen.dart';
import 'firebase_options.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ❗ ล็อกให้ใช้แนวตั้งอย่างเดียว
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(KinrooApp());
}

class KinrooApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ), // ✅ แสดงโหลดข้อมูลใน main()
            ),
          );
        }
        if (snapshot.hasError) {
          return MaterialApp(
            home: Scaffold(
              body: Center(child: Text("เกิดข้อผิดพลาดในการโหลด Firebase")),
            ),
          );
        }
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Kinroo',
          theme: ThemeData(
            fontFamily: 'Kanit',
            useMaterial3: true,
            primarySwatch: Colors.blue,
          ),
          home: IntroScreen(), // ✅ ไปยังหน้าเริ่มต้นเมื่อโหลด Firebase สำเร็จ
        );
      },
    );
  }
}
