import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_provider.dart';

// Food History State
class FoodItem {
  final String food;
  final int calories;
  final DateTime timestamp;

  FoodItem({
    required this.food,
    required this.calories,
    required this.timestamp,
  });

  factory FoodItem.fromFirestore(Map<String, dynamic> data) {
    return FoodItem(
      food: data['food'] ?? '',
      calories: (data['calories'] as num?)?.toInt() ?? 0,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {'food': food, 'calories': calories, 'timestamp': timestamp};
  }
}

// Food History Provider
final foodHistoryProvider = StreamProvider<List<FoodItem>>((ref) {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) {
      if (user == null) {
        return Stream.value(<FoodItem>[]);
      }

      // กำหนดช่วงเวลาของวันนี้
      DateTime today = DateTime.now();
      DateTime startOfDay = DateTime(today.year, today.month, today.day);
      DateTime endOfDay = startOfDay
          .add(Duration(days: 1))
          .subtract(Duration(milliseconds: 1));

      return ref
          .watch(firestoreProvider)
          .collection("users")
          .doc(user.uid)
          .collection("food_history")
          .where("timestamp", isGreaterThanOrEqualTo: startOfDay)
          .where("timestamp", isLessThanOrEqualTo: endOfDay)
          .snapshots()
          .map((querySnapshot) {
            return querySnapshot.docs
                .map((doc) => FoodItem.fromFirestore(doc.data()))
                .toList();
          });
    },
    loading: () => Stream.value(<FoodItem>[]),
    error: (_, __) => Stream.value(<FoodItem>[]),
  );
});

// Consumed Calories Provider
final consumedCaloriesProvider = Provider<int>((ref) {
  final foodHistory = ref.watch(foodHistoryProvider).value ?? [];
  return foodHistory.fold(0, (total, food) => total + food.calories);
});

// Food Service Provider
final foodServiceProvider = Provider<FoodService>((ref) {
  return FoodService(
    firestore: ref.watch(firestoreProvider),
    auth: ref.watch(firebaseAuthProvider),
  );
});

class FoodService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FoodService({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  }) : _firestore = firestore,
       _auth = auth;

  Future<void> addFoodToHistory(String foodName, int calories) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final foodItem = FoodItem(
      food: foodName,
      calories: calories,
      timestamp: DateTime.now(),
    );

    await _firestore
        .collection("users")
        .doc(user.uid)
        .collection("food_history")
        .add(foodItem.toFirestore());
  }

  Future<void> checkForNewDay() async {
    final prefs = await SharedPreferences.getInstance();
    String todayStr = DateTime.now().toIso8601String().substring(0, 10);
    String? lastRecordedDate = prefs.getString('last_date');

    if (lastRecordedDate != todayStr) {
      await prefs.setString('last_date', todayStr);
      // วันใหม่ - ข้อมูลจะถูกรีเซ็ตโดยอัตโนมัติผ่าน query ใน provider
    }
  }
}
