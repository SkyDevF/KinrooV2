import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'user_provider.dart';

class FoodMenuItem {
  final String name;
  final String image;
  final int calories;
  final String type;
  final List<String> allergy;

  FoodMenuItem({
    required this.name,
    required this.image,
    required this.calories,
    required this.type,
    required this.allergy,
  });
}

// Food Menu Data Provider
final foodMenuProvider = Provider<List<FoodMenuItem>>((ref) {
  return [
    FoodMenuItem(
      name: "ข้าวขาหมู",
      image: "assets/food/ข้าวขาหมู.jpg",
      calories: 550,
      type: "gain",
      allergy: [],
    ),
    FoodMenuItem(
      name: "ข้าวมันไก่",
      image: "assets/food/ข้าวมันไก่.jpg",
      calories: 600,
      type: "gain",
      allergy: [],
    ),
    FoodMenuItem(
      name: "ข้าวซอยไก่",
      image: "assets/food/ข้าวซอยไก่.jpg",
      calories: 500,
      type: "gain",
      allergy: ["นม"],
    ),
    FoodMenuItem(
      name: "หมูกระทะ",
      image: "assets/food/หมูกระทะ.jpg",
      calories: 600,
      type: "gain",
      allergy: [],
    ),
    FoodMenuItem(
      name: "ไก่ทอด",
      image: "assets/food/ไก่ทอด.jpg",
      calories: 600,
      type: "gain",
      allergy: [],
    ),
    FoodMenuItem(
      name: "ผัดไทย",
      image: "assets/food/ผัดไทย.jpg",
      calories: 550,
      type: "gain",
      allergy: ["ไข่"],
    ),
    FoodMenuItem(
      name: "หอยทอด",
      image: "assets/food/หอยทอด.jpg",
      calories: 550,
      type: "gain",
      allergy: ["ไข่"],
    ),
    FoodMenuItem(
      name: "ข้าวหมูทอดกระเทียม",
      image: "assets/food/ข้าวหมูทอดกระเทียม.jpg",
      calories: 550,
      type: "gain",
      allergy: [],
    ),
    FoodMenuItem(
      name: "สปาเกตตีผัดขี้เมา",
      image: "assets/food/สปาเกตตี้ผัดขี้เมา.jpg",
      calories: 550,
      type: "gain",
      allergy: ["ไข่"],
    ),
    FoodMenuItem(
      name: "ข้าวหมูแดง",
      image: "assets/food/ข้าวหมูแดง.jpg",
      calories: 500,
      type: "gain",
      allergy: [],
    ),
    FoodMenuItem(
      name: "ผัดกะเพราหมูกรอบ",
      image: "assets/food/ผัดกระเพราหมูกรอบ.jpg",
      calories: 500,
      type: "gain",
      allergy: ["ไข่"],
    ),
    FoodMenuItem(
      name: "ไส้กรอกอีสาน",
      image: "assets/food/ไส้กรอกอีสาน.jpg",
      calories: 500,
      type: "gain",
      allergy: [],
    ),
    FoodMenuItem(
      name: "ข้าวเหนียวหมูปิ้ง",
      image: "assets/food/ข้าวเหนียวหมูปิ้ง.jpg",
      calories: 450,
      type: "balanced",
      allergy: [],
    ),
    FoodMenuItem(
      name: "ข้าวผัดกุ้ง",
      image: "assets/food/ข้าวผัดกุ้ง.jpg",
      calories: 450,
      type: "balanced",
      allergy: ["กุ้ง", "ไข่"],
    ),
    FoodMenuItem(
      name: "แกงเขียวหวาน",
      image: "assets/food/แกงเขียวหวาน.jpg",
      calories: 450,
      type: "balanced",
      allergy: ["นม"],
    ),
    FoodMenuItem(
      name: "บะหมี่กึ่งสำเร็จรูป",
      image: "assets/food/มาม่า.jpg",
      calories: 450,
      type: "balanced",
      allergy: ["ไข่"],
    ),
    FoodMenuItem(
      name: "ไก่ย่าง",
      image: "assets/food/ไก่ย่าง.jpg",
      calories: 450,
      type: "balanced",
      allergy: [],
    ),
    FoodMenuItem(
      name: "ข้าวไข่เจียว",
      image: "assets/food/ข้าวไข่เจียว.jpg",
      calories: 420,
      type: "balanced",
      allergy: ["ไข่"],
    ),
    FoodMenuItem(
      name: "ลาบหมู",
      image: "assets/food/ลาบหมู.jpg",
      calories: 420,
      type: "balanced",
      allergy: [],
    ),
    FoodMenuItem(
      name: "ข้าวผัดไข่",
      image: "assets/food/ข้าวผัดไข่.jpg",
      calories: 400,
      type: "balanced",
      allergy: ["ไข่"],
    ),
    FoodMenuItem(
      name: "ต้มเนื้อ",
      image: "assets/food/ต้มเนื้อ.jpg",
      calories: 400,
      type: "balanced",
      allergy: [],
    ),
    FoodMenuItem(
      name: "ขนมจีนน้ำยา",
      image: "assets/food/ขนมจีนน้ำยา.jpg",
      calories: 400,
      type: "balanced",
      allergy: ["ปลา"],
    ),
    FoodMenuItem(
      name: "ปลาทอด",
      image: "assets/food/ปลาทอด.jpg",
      calories: 400,
      type: "balanced",
      allergy: ["ปลา"],
    ),
    FoodMenuItem(
      name: "สุกี้น้ำ",
      image: "assets/food/สุกี้น้ำ.jpg",
      calories: 400,
      type: "balanced",
      allergy: ["ไข่"],
    ),
    FoodMenuItem(
      name: "ลูกชิ้นหมู",
      image: "assets/food/ลูกชิ้นหมู.jpg",
      calories: 380,
      type: "balanced",
      allergy: [],
    ),
    FoodMenuItem(
      name: "ต้มยำกุ้ง",
      image: "assets/food/ต้มยำกุ้ง.jpg",
      calories: 360,
      type: "control",
      allergy: ["กุ้ง"],
    ),
    FoodMenuItem(
      name: "ต้มไก่",
      image: "assets/food/ต้มไก่.jpg",
      calories: 350,
      type: "control",
      allergy: [],
    ),
    FoodMenuItem(
      name: "ชาบู",
      image: "assets/food/ชาบู.jpg",
      calories: 350,
      type: "control",
      allergy: [],
    ),
    FoodMenuItem(
      name: "ยำทะเล",
      image: "assets/food/ยำทะเล.jpg",
      calories: 350,
      type: "control",
      allergy: ["กุ้ง", "ปลา"],
    ),
    FoodMenuItem(
      name: "แกงหน่อไม้",
      image: "assets/food/แกงหน่อไม้.jpg",
      calories: 350,
      type: "control",
      allergy: [],
    ),
    FoodMenuItem(
      name: "ไข่พะโล้",
      image: "assets/food/ไข่พะโล้.jpg",
      calories: 350,
      type: "control",
      allergy: ["ไข่"],
    ),
    FoodMenuItem(
      name: "ข้าวต้มหมูสับ",
      image: "assets/food/ข้าวต้มหมูสับ.jpg",
      calories: 340,
      type: "control",
      allergy: [],
    ),
    FoodMenuItem(
      name: "กระเพราเนื้อเปื่อย",
      image: "assets/food/กระเพราเนื้อเปื่อย.jpg",
      calories: 320,
      type: "control",
      allergy: ["ไข่"],
    ),
    FoodMenuItem(
      name: "ข้าวต้มกุ้ง",
      image: "assets/food/ข้าวต้มกุ้ง.jpg",
      calories: 320,
      type: "control",
      allergy: ["กุ้ง"],
    ),
    FoodMenuItem(
      name: "ผัดผักรวมมิตร",
      image: "assets/food/ผัดผักรวมมิตร.jpg",
      calories: 300,
      type: "control",
      allergy: [],
    ),
    FoodMenuItem(
      name: "กระเพราหมูสับ",
      image: "assets/food/กระเพราหมูสับ.jpg",
      calories: 300,
      type: "control",
      allergy: ["ไข่"],
    ),
    FoodMenuItem(
      name: "ข้าวต้มปลา",
      image: "assets/food/ข้าวต้มปลา.jpg",
      calories: 300,
      type: "control",
      allergy: ["ปลา"],
    ),
    FoodMenuItem(
      name: "ซูชิ",
      image: "assets/food/ซูชิ.jpg",
      calories: 280,
      type: "control",
      allergy: ["ปลา"],
    ),
    FoodMenuItem(
      name: "กระเพราไก่",
      image: "assets/food/กระเพราไก่.jpg",
      calories: 280,
      type: "control",
      allergy: ["ไข่"],
    ),
    FoodMenuItem(
      name: "สลัดผัก",
      image: "assets/food/สลัดผัก.jpg",
      calories: 250,
      type: "control",
      allergy: [],
    ),
    FoodMenuItem(
      name: "ก๋วยเตี๋ยว",
      image: "assets/food/ก๋วยเตี๋ยว.jpg",
      calories: 250,
      type: "control",
      allergy: [],
    ),
    FoodMenuItem(
      name: "แกงจืด",
      image: "assets/food/แกงจืด.jpg",
      calories: 250,
      type: "control",
      allergy: [],
    ),
    FoodMenuItem(
      name: "ส้มตำ",
      image: "assets/food/ส้มตำ.jpg",
      calories: 200,
      type: "control",
      allergy: [],
    ),
  ];
});

// Recommended Food Provider based on BMI
final recommendedFoodProvider = Provider<List<FoodMenuItem>>((ref) {
  final bmi = ref.watch(bmiProvider);
  final foodMenu = ref.watch(foodMenuProvider);

  // เลือกประเภทเมนูตาม BMI
  String category;
  if (bmi < 18.5) {
    category = "gain";
  } else if (bmi < 25) {
    category = "balanced";
  } else {
    category = "control";
  }

  // ตัวอย่าง allergy (ในอนาคตสามารถดึงจาก user profile ได้)
  List<String> userAllergy = [];

  // กรองเมนูที่ตรงประเภทและไม่ใช่อาหารที่แพ้
  final filteredMenu = foodMenu.where((menu) {
    return menu.type == category &&
        !menu.allergy.any((a) => userAllergy.contains(a));
  }).toList();

  // สุ่มและจำกัด 3 รายการ
  filteredMenu.shuffle();
  return filteredMenu.take(3).toList();
});
