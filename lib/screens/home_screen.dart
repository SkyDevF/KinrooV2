import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_screen.dart';
import 'food_history_screen.dart';
import 'scan_food_screen.dart';
import 'package:crystal_navigation_bar/crystal_navigation_bar.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ต้องเพิ่ม

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

// This widget serves as the main home screen of the app, displaying user health data, food history, and navigation options.
class _HomeScreenState extends State<HomeScreen> {
  String username = "กำลังโหลด...", gender = "";
  double weight = 0.0, height = 0.0, targetWeight = 0.0, startWeight = 75.0;
  int calorieGoal = 2000, consumedCalories = 0, currentIndex = 0;
  DateTime today = DateTime.now();
  List<DateTime> weekDays = [];
  List<Map<String, dynamic>> foodHistory = [];

  final thaiWeekDays = {
    1: "จ.",
    2: "อ.",
    3: "พ.",
    4: "พฤ.",
    5: "ศ.",
    6: "ส.",
    7: "อา.",
  };

  @override
  void initState() {
    super.initState();
    _generateWeek();
    _checkForNewDay();
  }

  void _checkForNewDay() async {
    final prefs = await SharedPreferences.getInstance();
    String todayStr = DateTime.now().toIso8601String().substring(0, 10);
    String? lastRecordedDate = prefs.getString('last_date');

    if (lastRecordedDate != todayStr) {
      // วันใหม่ → รีเซ็ตอาหารและแคลอรี่
      await prefs.setString('last_date', todayStr);

      // รีเซ็ตข้อมูลใน State
      setState(() {
        foodHistory = [];
        consumedCalories = 0;
      });
    }

    _loadAllData(); // โหลดข้อมูลหลังจากตรวจวัน
  }

  void _loadAllData() async {
    await Future.wait([
      fetchUserData(),
      fetchDailyCalories(),
      fetchFoodHistory(),
    ]);
  }

  void _generateWeek() {
    DateTime firstDay = today.subtract(Duration(days: today.weekday - 1));
    weekDays = List.generate(7, (i) => firstDay.add(Duration(days: i)));
  }

  Future<void> fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await user.reload();
    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((doc) {
          if (doc.exists && mounted)
            setState(() {
              username = doc['name'];
              gender = doc['gender'];
              weight = double.tryParse(doc['weight'].toString()) ?? 0.0;
              height = double.tryParse(doc['height'].toString()) ?? 0.0;
              targetWeight =
                  double.tryParse(doc['targetWeight'].toString()) ?? weight;
            });
        });
  }

  Future<void> fetchDailyCalories() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    var doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (doc.exists && mounted) {
      setState(() => calorieGoal = doc.get("daily_calories") ?? 2000);
    }
  }

  Future<void> fetchFoodHistory() async {
    try {
      String userId = FirebaseAuth.instance.currentUser?.uid ?? "unknown_user";

      // กำหนดช่วงเวลาของวันนี้ (00:00:00 - 23:59:59)
      DateTime today = DateTime.now();
      DateTime startOfDay = DateTime(today.year, today.month, today.day);
      DateTime endOfDay = startOfDay
          .add(Duration(days: 1))
          .subtract(Duration(milliseconds: 1));

      var snapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .collection("food_history")
          .where("timestamp", isGreaterThanOrEqualTo: startOfDay)
          .where("timestamp", isLessThanOrEqualTo: endOfDay)
          .get();

      List<Map<String, dynamic>> foodList = snapshot.docs
          .map((doc) => doc.data())
          .toList();

      setState(() {
        foodHistory = foodList;
        consumedCalories = foodList.fold(
          0,
          (sum, food) => sum + (food["calories"] as num).toInt(),
        );
      });
    } catch (e) {
      print("❌ เกิดข้อผิดพลาดขณะดึงข้อมูลจาก Firebase: $e");
    }
  }

  // Computed properties
  double get bmi => (weight == 0 || height == 0)
      ? 0.0
      : weight / ((height / 100) * (height / 100));
  String get healthAdvice => bmi < 18.5
      ? "ควรรับประทานอาหารให้ครบ 5 หมู่"
      : bmi <= 24.9
      ? "รักษาสมดุลอาหารและออกกำลังกาย"
      : "ควรควบคุมอาหารและออกกำลังกาย";
  String get bmiImage =>
      'assets/bmi/${gender == "ชาย" ? "man" : "girl"}_${_getBmiRange()}.png';

  String _getBmiRange() {
    if (bmi < 18.5) return "18.5";
    if (bmi <= 24.5) return "18.5-24.5";
    if (bmi <= 30) return "25-30";
    if (bmi <= 39.5) return "35-39.5";
    return "40";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 47, 130, 174),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            _buildWeekDays(),
            _buildHealthInfo(),
            _buildWeightGoal(),
            _buildFoodRecommendation(),
          ],
        ),
      ),
      bottomNavigationBar: _buildNavigation(),
    );
  }

  Widget _buildContainer({
    required Widget child,
    EdgeInsets? margin,
    EdgeInsets? padding,
  }) {
    return Container(
      margin: margin ?? EdgeInsets.all(25),
      padding: padding ?? EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 30, spreadRadius: 20),
        ],
      ),
      child: child,
    );
  }

  Widget _buildProgressBar(double value, {Color? color, double height = 25}) {
    return LinearProgressIndicator(
      value: value,
      backgroundColor: Colors.grey[300],
      color: color ?? Color.fromARGB(255, 70, 51, 43),
      minHeight: height,
    );
  }

  Widget _buildHealthInfo() {
    return _buildContainer(
      child: Row(
        children: [
          Image.asset(bmiImage, width: 110, height: 222, fit: BoxFit.cover),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "ข้อมูลสุขภาพ คุณ$username",
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 70, 51, 43),
                  ),
                ),
                Text(
                  "ค่า BMI ของคุณ: ${bmi.toStringAsFixed(1)}",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 84, 69, 53),
                  ),
                ),
                Text(
                  healthAdvice,
                  style: TextStyle(
                    fontSize: 10,
                    color: Color.fromARGB(255, 70, 51, 43),
                  ),
                ),
                SizedBox(height: 15),
                _buildProgressBar(
                  consumedCalories / calorieGoal,
                  color: consumedCalories >= calorieGoal
                      ? Colors.red
                      : Color.fromARGB(255, 70, 51, 43),
                  height: 35,
                ),
                SizedBox(height: 10),
                Center(
                  child: Text(
                    "$consumedCalories / $calorieGoal kcal",
                    style: TextStyle(fontSize: 14, color: Colors.black),
                  ),
                ),
                if (foodHistory.isNotEmpty) _buildFoodList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodList() {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "อาหารที่กินวันนี้",
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
          ...foodHistory.map(
            (food) => Text(
              "${food["food"]} (${food["calories"]} kcal)",
              style: TextStyle(fontSize: 9, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightGoal() {
  double? progressValue = 0;
  if (startWeight != 0 && targetWeight != 0 && weight != 0) {
    double totalDiff = (targetWeight - startWeight).abs().toDouble();
    double currentDiff = (weight - targetWeight).abs().toDouble();
    progressValue =
        (totalDiff == 0 ? 1.0 : (1.0 - (currentDiff / totalDiff))).clamp(0.0, 1.0);
  }
  int percentage = (progressValue * 100).round();

  return _buildContainer(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "เป้าหมายน้ำหนัก",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        Text(
          "ปัจจุบัน: ${weight.toStringAsFixed(1)} kg",
          style: TextStyle(fontSize: 14),
        ),
        Text(
          "เป้าหมาย: ${targetWeight.toStringAsFixed(1)} kg",
          style: TextStyle(fontSize: 14),
        ),
        SizedBox(height: 15),
        _buildProgressBar(
          progressValue,
          color: percentage >= 100
              ? Colors.green
              : Color.fromARGB(255, 47, 130, 174),
        ),
        SizedBox(height: 10),
        Text(
          "$percentage% สำเร็จ",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: percentage >= 100 ? Colors.green : Colors.black,
          ),
        ),
      ],
    ),
  );
}


Widget _buildFoodRecommendation() {
  final foodMenu = [
  {
    "name": "ข้าวขาหมู",
    "image": "assets/food/ข้าวขาหมู.jpg",
    "calories": 550,
    "type": "gain",
    "allergy": []
  },
  {
    "name": "ข้าวมันไก่",
    "image": "assets/food/ข้าวมันไก่.jpg",
    "calories": 600,
    "type": "gain",
    "allergy": []
  },
  {
    "name": "ข้าวซอยไก่",
    "image": "assets/food/ข้าวซอยไก่.jpg",
    "calories": 500,
    "type": "gain",
    "allergy": ["นม"]
  },
  {
    "name": "หมูกระทะ",
    "image": "assets/food/หมูกระทะ.jpg",
    "calories": 600,
    "type": "gain",
    "allergy": []
  },
  {
    "name": "ไก่ทอด",
    "image": "assets/food/ไก่ทอด.jpg",
    "calories": 600,
    "type": "gain",
    "allergy": []
  },
  {
    "name": "ผัดไทย",
    "image": "assets/food/ผัดไทย.jpg",
    "calories": 550,
    "type": "gain",
    "allergy": ["ไข่"]
  },
  {
    "name": "หอยทอด",
    "image": "assets/food/หอยทอด.jpg",
    "calories": 550,
    "type": "gain",
    "allergy": ["ไข่"]
  },
  {
    "name": "ข้าวหมูทอดกระเทียม",
    "image": "assets/food/ข้าวหมูทอดกระเทียม.jpg",
    "calories": 550,
    "type": "gain",
    "allergy": []
  },
  {
    "name": "สปาเกตตีผัดขี้เมา",
    "image": "assets/food/สปาเกตตีผัดขี้เมา.jpg",
    "calories": 550,
    "type": "gain",
    "allergy": ["ไข่"]
  },
  {
    "name": "ข้าวหมูแดง",
    "image": "assets/food/ข้าวหมูแดง.jpg",
    "calories": 500,
    "type": "gain",
    "allergy": []
  },
  {
    "name": "ผัดกะเพราหมูกรอบ",
    "image": "assets/food/ผัดกะเพราหมูกรอบ.jpg",
    "calories": 500,
    "type": "gain",
    "allergy": []
  },
  {
    "name": "ไส้กรอกอีสาน",
    "image": "assets/food/ไส้กรอกอีสาน.jpg",
    "calories": 500,
    "type": "gain",
    "allergy": []
  },
  {
    "name": "ข้าวเหนียวหมูปิ้ง",
    "image": "assets/food/ข้าวเหนียวหมูปิ้ง.jpg",
    "calories": 450,
    "type": "balanced",
    "allergy": []
  },
  {
    "name": "ข้าวผัดกุ้ง",
    "image": "assets/food/ข้าวผัดกุ้ง.jpg",
    "calories": 450,
    "type": "balanced",
    "allergy": ["กุ้ง", "ไข่"]
  },
  {
    "name": "แกงเขียวหวาน",
    "image": "assets/food/แกงเขียวหวาน.jpg",
    "calories": 450,
    "type": "balanced",
    "allergy": ["นม"]
  },
  {
    "name": "บะหมี่กึ่งสำเร็จรูป",
    "image": "assets/food/บะหมี่กึ่งสำเร็จรูป.jpg",
    "calories": 450,
    "type": "balanced",
    "allergy": ["ไข่"]
  },
  {
    "name": "ไก่ย่าง",
    "image": "assets/food/ไก่ย่าง.jpg",
    "calories": 450,
    "type": "balanced",
    "allergy": []
  },
  {
    "name": "ข้าวไข่เจียว",
    "image": "assets/food/ข้าวไข่เจียว.jpg",
    "calories": 420,
    "type": "balanced",
    "allergy": ["ไข่"]
  },
  {
    "name": "ลาบหมู",
    "image": "assets/food/ลาบหมู.jpg",
    "calories": 420,
    "type": "balanced",
    "allergy": []
  },
  {
    "name": "ข้าวผัดไข่",
    "image": "assets/food/ข้าวผัดไข่.jpg",
    "calories": 400,
    "type": "balanced",
    "allergy": ["ไข่"]
  },
  {
    "name": "ต้มเนื้อ",
    "image": "assets/food/ต้มเนื้อ.jpg",
    "calories": 400,
    "type": "balanced",
    "allergy": []
  },
  {
    "name": "ขนมจีนน้ำยา",
    "image": "assets/food/ขนมจีนน้ำยา.jpg",
    "calories": 400,
    "type": "balanced",
    "allergy": ["ปลา"]
  },
  {
    "name": "ปลาทอด",
    "image": "assets/food/ปลาทอด.jpg",
    "calories": 400,
    "type": "balanced",
    "allergy": ["ปลา"]
  },
  {
    "name": "สุกี้น้ำ",
    "image": "assets/food/สุกี้น้ำ.jpg",
    "calories": 400,
    "type": "balanced",
    "allergy": ["ไข่"]
  },
  {
    "name": "ลูกชิ้นหมู",
    "image": "assets/food/ลูกชิ้นหมู.jpg",
    "calories": 380,
    "type": "balanced",
    "allergy": []
  },
  {
    "name": "ต้มยำกุ้ง",
    "image": "assets/food/ต้มยำกุ้ง.jpg",
    "calories": 360,
    "type": "control",
    "allergy": ["กุ้ง"]
  },
  {
    "name": "ต้มไก่",
    "image": "assets/food/ต้มไก่.jpg",
    "calories": 350,
    "type": "control",
    "allergy": []
  },
  {
    "name": "ชาบู",
    "image": "assets/food/ชาบู.jpg",
    "calories": 350,
    "type": "control",
    "allergy": []
  },
  {
    "name": "ยำทะเล",
    "image": "assets/food/ยำทะเล.jpg",
    "calories": 350,
    "type": "control",
    "allergy": ["กุ้ง", "ปลา"]
  },
  {
    "name": "แกงหน่อไม้",
    "image": "assets/food/แกงหน่อไม้.jpg",
    "calories": 350,
    "type": "control",
    "allergy": []
  },
  {
    "name": "ไข่พะโล้",
    "image": "assets/food/ไข่พะโล้.jpg",
    "calories": 350,
    "type": "control",
    "allergy": ["ไข่"]
  },
  {
    "name": "ข้าวต้มหมูสับ",
    "image": "assets/food/ข้าวต้มหมูสับ.jpg",
    "calories": 340,
    "type": "control",
    "allergy": []
  },
  {
    "name": "กระเพราเนื้อเปื่อย",
    "image": "assets/food/กระเพราเนื้อเปื่อย.jpg",
    "calories": 320,
    "type": "control",
    "allergy": []
  },
  {
    "name": "ข้าวต้มกุ้ง",
    "image": "assets/food/ข้าวต้มกุ้ง.jpg",
    "calories": 320,
    "type": "control",
    "allergy": ["กุ้ง"]
  },
  {
    "name": "ผัดผักรวมมิตร",
    "image": "assets/food/ผัดผักรวมมิตร.jpg",
    "calories": 300,
    "type": "control",
    "allergy": []
  },
  {
    "name": "กระเพราหมูสับ",
    "image": "assets/food/กระเพราหมูสับ.jpg",
    "calories": 300,
    "type": "control",
    "allergy": []
  },
  {
    "name": "ข้าวต้มปลา",
    "image": "assets/food/ข้าวต้มปลา.jpg",
    "calories": 300,
    "type": "control",
    "allergy": ["ปลา"]
  },
  {
    "name": "ซูชิ",
    "image": "assets/food/ซูชิ.jpg",
    "calories": 280,
    "type": "control",
    "allergy": ["ปลา"]
  },
  {
    "name": "กระเพราไก่",
    "image": "assets/food/กระเพราไก่.jpg",
    "calories": 280,
    "type": "control",
    "allergy": []
  },
  {
    "name": "สลัดผัก",
    "image": "assets/food/สลัดผัก.jpg",
    "calories": 250,
    "type": "control",
    "allergy": []
  },
  {
    "name": "ก๋วยเตี๋ยว",
    "image": "assets/food/ก๋วยเตี๋ยว.jpg",
    "calories": 250,
    "type": "control",
    "allergy": []
  },
  {
    "name": "แกงจืด",
    "image": "assets/food/แกงจืด.jpg",
    "calories": 250,
    "type": "control",
    "allergy": []
  },
  {
    "name": "ส้มตำ",
    "image": "assets/food/ส้มตำ.jpg",
    "calories": 200,
    "type": "control",
    "allergy": []
  },
];


 // คำนวณ BMI
  double bmi = (weight == 0 || height == 0)
      ? 0.0
      : weight / ((height / 100) * (height / 100));

  // เลือกประเภทเมนูตาม BMI
  String category;
  if (bmi < 18.5) {
    category = "gain";
  } else if (bmi < 25) {
    category = "balanced";
  } else {
    category = "control";
  }

  // ตัวอย่าง allergy (ดึงจาก Firebase ได้)
  List<String> userAllergy = []; // เช่น ["ไข่", "นม"]

  // กรองเมนูที่ตรงประเภทและไม่ใช่อาหารที่แพ้
  final filteredMenu = foodMenu.where((menu) {
    return menu["type"] == category &&
        !(menu["allergy"] as List).any((a) => userAllergy.contains(a));
  }).toList();

  // สุ่มและจำกัด 3 รายการ
  filteredMenu.shuffle();
  final displayedMenus = filteredMenu.take(3).toList();

  return _buildContainer(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("แนะนำเมนูอาหาร", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 15),
        Container(
          height: 200,
          child: displayedMenus.isEmpty
              ? Center(child: Text("ไม่พบเมนูที่เหมาะสมกับสุขภาพของคุณ"))
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: displayedMenus.length,
                  itemBuilder: (ctx, index) {
                    final item = displayedMenus[index];
                    final path = item["image"].toString();

                    return Container(
                      width: 150,
                      margin: EdgeInsets.only(right: 15),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: path.startsWith("assets/")
                                ? Image.asset(
                                    path,
                                    width: 150,
                                    height: 130,
                                    fit: BoxFit.cover,
                                  )
                                : Image.network(
                                    path,
                                    width: 150,
                                    height: 130,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (c, child, progress) {
                                      if (progress == null) return child;
                                      return Container(
                                        width: 150,
                                        height: 130,
                                        child: Center(child: CircularProgressIndicator()),
                                      );
                                    },
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 150,
                                      height: 130,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                                    ),
                                  ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            item["name"].toString(),
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            "${item["calories"]} kcal",
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    ),
  );
}

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      color: Color.fromARGB(255, 70, 51, 43),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.person, size: 30, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ProfileScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekDays() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: weekDays.map(_weekDayContainer).toList(),
      ),
    );
  }

  Widget _weekDayContainer(DateTime date) {
    bool isToday =
        date.day == today.day &&
        date.month == today.month &&
        date.year == today.year;
    return Container(
      alignment: Alignment.center,
      width: 50,
      height: 70,
      decoration: BoxDecoration(
        color: isToday ? Color.fromARGB(255, 70, 51, 43) : Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.grey),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            thaiWeekDays[date.weekday] ?? "",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isToday ? Colors.white : Colors.black,
            ),
          ),
          Text(
            "${date.day}",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isToday ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigation() {
    return CrystalNavigationBar(
      onTap: (index) {
        setState(() => currentIndex = index);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                [ScanFoodScreen(), FoodHistoryScreen(), ProfileScreen()][index],
          ),
        );
      },
      backgroundColor: Color.fromARGB(255, 70, 51, 43),
      currentIndex: currentIndex,
      items: [Icons.camera_alt, Icons.history, Icons.person]
          .map(
            (icon) => CrystalNavigationBarItem(
              icon: icon,
              unselectedColor: Colors.white,
              selectedColor: Colors.white,
            ),
          )
          .toList(),
    );
  }
}
