import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import 'welcome_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider);

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
      body: userProfileAsync.when(
        data: (userProfile) => _buildProfileContent(context, ref, userProfile),
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('เกิดข้อผิดพลาด: $error')),
      ),
    );
  }

  Widget _buildProfileContent(
    BuildContext context,
    WidgetRef ref,
    UserProfile? userProfile,
  ) {
    if (userProfile == null) {
      return Center(
        child: Text(
          'ไม่พบข้อมูลผู้ใช้',
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/icon/sum.png',
            width: 200,
            height: 200,
            fit: BoxFit.cover,
          ),
          SizedBox(height: 20),

          Text(
            userProfile.name,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.brown[800],
            ),
          ),
          Text(
            userProfile.email,
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
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
                  "น้ำหนัก: ${userProfile.weight.toStringAsFixed(1)} กก.",
                  style: TextStyle(fontSize: 18),
                ),
                Text(
                  "ส่วนสูง: ${userProfile.height.toStringAsFixed(1)} ซม.",
                  style: TextStyle(fontSize: 18),
                ),
                Text(
                  "เป้าหมายน้ำหนัก: ${userProfile.targetWeight.toStringAsFixed(1)} กก.",
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
              // ข้อมูลจะอัปเดตอัตโนมัติผ่าน Stream
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
              final authService = ref.read(authServiceProvider);
              await authService.signOut();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => WelcomeScreen()),
                );
              }
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
    );
  }
}
