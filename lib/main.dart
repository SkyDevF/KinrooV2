import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/intro_screen.dart';
import 'firebase_options.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ❗ ล็อกให้ใช้แนวตั้งอย่างเดียว
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

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
      ),
      home: IntroScreen(), // ✅ ไปยังหน้าเริ่มต้นเมื่อโหลด Firebase สำเร็จ
    );
  }
}
