import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/intro_screen.dart';
import 'firebase_options.dart';
import 'package:flutter/services.dart';
import 'utils/system_ui_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ❗ ล็อกให้ใช้แนวตั้งอย่างเดียว
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // ตั้งค่า Edge-to-Edge สำหรับ Android 15+
  SystemUIHelper.setupEdgeToEdge();

  runApp(ProviderScope(child: KinrooApp()));
}

class KinrooApp extends ConsumerWidget {
  const KinrooApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kinroo',
      theme: ThemeData(
        fontFamily: 'Kanit',
        useMaterial3: true,
        primarySwatch: Colors.blue,
        // ตั้งค่า AppBar theme สำหรับ Edge-to-Edge
        appBarTheme: const AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
          ),
        ),
      ),
      darkTheme: ThemeData(
        fontFamily: 'Kanit',
        useMaterial3: true,
        brightness: Brightness.dark,
        // ตั้งค่า AppBar theme สำหรับ Dark Mode
        appBarTheme: const AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
          ),
        ),
      ),
      home: IntroScreen(), // ✅ ไปยังหน้าเริ่มต้นเมื่อโหลด Firebase สำเร็จ
    );
  }
}
