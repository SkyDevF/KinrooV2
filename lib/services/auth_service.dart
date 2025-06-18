import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  Future<void> logoutAndLoginNewAccount() async {
    await FirebaseAuth.instance.signOut();
    await Future.delayed(Duration(seconds: 1));
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null) {
        // ✅ ล็อกเอาต์แล้ว ไปหน้า WelcomeScreen
      } else {
        // ✅ ล็อกอินใหม่ รีเฟรชบัญชี
        user.reload();
      }
    });
  }
}