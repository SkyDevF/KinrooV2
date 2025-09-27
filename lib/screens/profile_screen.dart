import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import 'welcome_screen.dart';
import 'edit_profile_screen.dart';

// Provider สำหรับจัดการรูปโปรไฟล์ที่เก็บใน SharedPreferences
final profileImageProvider = StateNotifierProvider<ProfileImageNotifier, File?>(
  (ref) {
    return ProfileImageNotifier();
  },
);

class ProfileImageNotifier extends StateNotifier<File?> {
  ProfileImageNotifier() : super(null) {
    _loadProfileImage();
  }

  // โหลดรูปโปรไฟล์จาก SharedPreferences
  Future<void> _loadProfileImage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final imagePath = prefs.getString('profile_image_path');

      if (imagePath != null && imagePath.isNotEmpty) {
        final file = File(imagePath);
        if (await file.exists()) {
          state = file;
        } else {
          // ถ้าไฟล์ไม่มีแล้ว ให้ลบ path ออกจาก SharedPreferences
          await prefs.remove('profile_image_path');
        }
      }
    } catch (e) {
      debugPrint('Error loading profile image: $e');
    }
  }

  // บันทึกรูปโปรไฟล์
  Future<void> setProfileImage(File imageFile) async {
    try {
      // คัดลอกไฟล์ไปยัง app directory
      final appDir = await getApplicationDocumentsDirectory();
      final fileName =
          'profile_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage = await imageFile.copy('${appDir.path}/$fileName');

      // บันทึก path ใน SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_image_path', savedImage.path);

      // อัปเดต state
      state = savedImage;
    } catch (e) {
      debugPrint('Error saving profile image: $e');
    }
  }

  // ลบรูปโปรไฟล์ (เมื่อล็อกเอาท์)
  Future<void> clearProfileImage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final imagePath = prefs.getString('profile_image_path');

      // ลบไฟล์รูปภาพ
      if (imagePath != null) {
        final file = File(imagePath);
        if (await file.exists()) {
          await file.delete();
        }
      }

      // ลบ path จาก SharedPreferences
      await prefs.remove('profile_image_path');

      // อัปเดต state
      state = null;
    } catch (e) {
      debugPrint('Error clearing profile image: $e');
    }
  }
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  // ฟังก์ชันเลือกรูปภาพ
  Future<void> _pickImage(WidgetRef ref) async {
    final ImagePicker picker = ImagePicker();

    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        final File imageFile = File(image.path);
        // ใช้ notifier เพื่อบันทึกรูปภาพ
        await ref
            .read(profileImageProvider.notifier)
            .setProfileImage(imageFile);
      }
    } catch (e) {
      // Handle error silently or show user-friendly message
      debugPrint('Error picking image: $e');
    }
  }

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

    final authService = ref.watch(authServiceProvider);
    final isTrialAccount = authService.isAnonymousUser();

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ✅ แสดงแจ้งเตือนสำหรับบัญชีทดลอง
              if (isTrialAccount)
                Container(
                  margin: EdgeInsets.all(20),
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 5),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.warning, color: Colors.white, size: 30),
                      SizedBox(height: 10),
                      Text(
                        "คุณกำลังใช้บัญชีทดลอง",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        "ข้อมูลจะหายหากลบแอปและโหลดใหม่",
                        style: TextStyle(fontSize: 14, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

              // รูปโปรไฟล์แบบวงกลม
              _buildProfileImage(ref),
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
                  await Navigator.push(
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
                  // ลบรูปโปรไฟล์ก่อนล็อกเอาท์
                  await ref
                      .read(profileImageProvider.notifier)
                      .clearProfileImage();

                  final authService = ref.read(authServiceProvider);
                  await authService.signOut();
                  if (context.mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                    );
                  }
                },
                child: Text(
                  isTrialAccount ? "ออกจากบัญชีทดลอง" : "ล็อกเอาท์",
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
      ),
    );
  }

  // Widget สำหรับแสดงรูปโปรไฟล์
  Widget _buildProfileImage(WidgetRef ref) {
    final profileImage = ref.watch(profileImageProvider);

    return GestureDetector(
      onTap: () => _pickImage(ref),
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: ClipOval(
          child: profileImage != null
              ? Image.file(
                  profileImage,
                  width: 150,
                  height: 150,
                  fit: BoxFit.cover,
                )
              : Container(
                  width: 150,
                  height: 150,
                  color: Colors.grey[200],
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person, size: 60, color: Colors.grey[600]),
                      SizedBox(height: 8),
                      Text(
                        'แตะเพื่อเพิ่มรูป',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
