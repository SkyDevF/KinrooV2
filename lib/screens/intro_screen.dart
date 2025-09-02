import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'home_screen.dart';
import 'welcome_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ✅ นำเข้า SharedPreferences

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  _IntroScreenState createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset("assets/videos/intro.mp4")
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });

    // ✅ ตรวจสอบสถานะล็อกอินแบบเรียลไทม์
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      Future.delayed(Duration(seconds: 5), () {
        if (user == null) {
          // ✅ ผู้ใช้ล็อกเอาต์ → บันทึกสถานะแล้วไปหน้า WelcomeScreen
          prefs.setBool('isLoggedIn', false);
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => WelcomeScreen()));
        } else {
          // ✅ ผู้ใช้ล็อกอิน → ลบสถานะล็อกเอาต์แล้วไปหน้า HomeScreen
          prefs.setBool('isLoggedIn', true);
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen()));
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _controller.value.isInitialized
          ? SizedBox.expand(child: FittedBox(fit: BoxFit.cover, child: SizedBox(width: _controller.value.size.width, height: _controller.value.size.height, child: VideoPlayer(_controller))))
          : Center(child: CircularProgressIndicator()),
    );
  }
}