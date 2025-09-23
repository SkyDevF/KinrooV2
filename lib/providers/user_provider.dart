import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_provider.dart';

// User Profile State
class UserProfile {
  final String name;
  final String email;
  final String gender;
  final double weight;
  final double height;
  final double targetWeight;
  final int dailyCalories;

  UserProfile({
    required this.name,
    required this.email,
    required this.gender,
    required this.weight,
    required this.height,
    required this.targetWeight,
    required this.dailyCalories,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc, String email) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // ✅ ถ้าเป็นบัญชีทดลอง ให้ใช้ชื่อจากข้อมูลที่บันทึกไว้
    String displayName = data['name'] ?? 'ผู้ใช้ทดลอง';
    String displayEmail = email.isEmpty ? 'บัญชีทดลอง' : email;

    return UserProfile(
      name: displayName,
      email: displayEmail,
      gender: data['gender'] ?? '',
      weight: double.tryParse(data['weight'].toString()) ?? 0.0,
      height: double.tryParse(data['height'].toString()) ?? 0.0,
      targetWeight: double.tryParse(data['targetWeight'].toString()) ?? 0.0,
      dailyCalories: data['daily_calories'] ?? 2000,
    );
  }

  UserProfile copyWith({
    String? name,
    String? email,
    String? gender,
    double? weight,
    double? height,
    double? targetWeight,
    int? dailyCalories,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      targetWeight: targetWeight ?? this.targetWeight,
      dailyCalories: dailyCalories ?? this.dailyCalories,
    );
  }
}

// Provider สำหรับ User Profile
final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) {
      if (user == null) {
        return Stream.value(null);
      }

      final userDoc = ref.watch(userDataProvider(user.uid));
      return userDoc.when(
        data: (doc) {
          if (doc?.exists == true) {
            return Stream.value(
              UserProfile.fromFirestore(doc!, user.email ?? ''),
            );
          } else {
            return Stream.value(null);
          }
        },
        loading: () => Stream.value(null),
        error: (_, __) => Stream.value(null),
      );
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

// BMI Calculator
final bmiProvider = Provider<double>((ref) {
  final userProfile = ref.watch(userProfileProvider).value;
  if (userProfile == null ||
      userProfile.weight == 0 ||
      userProfile.height == 0) {
    return 0.0;
  }
  return userProfile.weight /
      ((userProfile.height / 100) * (userProfile.height / 100));
});

// Health Advice Provider
final healthAdviceProvider = Provider<String>((ref) {
  final bmi = ref.watch(bmiProvider);
  if (bmi < 18.5) {
    return "ควรรับประทานอาหารให้ครบ 5 หมู่";
  }
  if (bmi <= 24.9) {
    return "รักษาสมดุลอาหารและออกกำลังกาย";
  }
  return "ควรควบคุมอาหารและออกกำลังกาย";
});

// BMI Image Provider
final bmiImageProvider = Provider<String>((ref) {
  final userProfile = ref.watch(userProfileProvider).value;
  final bmi = ref.watch(bmiProvider);

  if (userProfile == null) {
    return 'assets/bmi/man_18.5-24.5.png';
  }

  String gender = userProfile.gender == "ชาย" ? "man" : "girl";
  String range;

  if (bmi < 18.5) {
    range = "18.5";
  } else if (bmi <= 24.5) {
    range = "18.5-24.5";
  } else if (bmi <= 30) {
    range = "25-30";
  } else if (bmi <= 39.5) {
    range = "35-39.5";
  } else {
    range = "40";
  }

  return 'assets/bmi/${gender}_$range.png';
});
