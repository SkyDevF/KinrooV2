import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_screen.dart';
import 'food_history_screen.dart';
import 'scan_food_screen.dart';
import 'package:crystal_navigation_bar/crystal_navigation_bar.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String username = "กำลังโหลด...", gender = "";
  double weight = 0.0, height = 0.0, targetWeight = 0.0, startWeight = 75.0;
  int calorieGoal = 2000, consumedCalories = 0, currentIndex = 0;
  DateTime today = DateTime.now();
  List<DateTime> weekDays = [];
  List<Map<String, dynamic>> foodHistory = [];

  final thaiWeekDays = {1: "จ.", 2: "อ.", 3: "พ.", 4: "พฤ.", 5: "ศ.", 6: "ส.", 7: "อา."};

  @override
  void initState() {
    super.initState();
    _generateWeek();
    _loadAllData();
  }

  void _loadAllData() async {
    await Future.wait([fetchUserData(), fetchDailyCalories(), fetchFoodHistory()]);
  }

  void _generateWeek() {
    DateTime firstDay = today.subtract(Duration(days: today.weekday - 1));
    weekDays = List.generate(7, (i) => firstDay.add(Duration(days: i)));
  }

  Future<void> fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await user.reload();
    FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots().listen((doc) {
      if (doc.exists && mounted) setState(() {
        username = doc['name'];
        gender = doc['gender'];
        weight = double.tryParse(doc['weight'].toString()) ?? 0.0;
        height = double.tryParse(doc['height'].toString()) ?? 0.0;
        targetWeight = double.tryParse(doc['targetWeight'].toString()) ?? weight;
      });
    });
  }

  Future<void> fetchDailyCalories() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    var doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (doc.exists && mounted) {
      setState(() => calorieGoal = doc.get("daily_calories") ?? 2000);
    }
  }

  Future<void> fetchFoodHistory() async {
    try {
      String userId = FirebaseAuth.instance.currentUser?.uid ?? "unknown_user";
      var snapshot = await FirebaseFirestore.instance
          .collection("users").doc(userId).collection("food_history").get();

      List<Map<String, dynamic>> foodList = snapshot.docs.map((doc) => doc.data()).toList();
      
      setState(() {
        foodHistory = foodList;
        consumedCalories = foodList.fold(0, (sum, food) => sum + (food["calories"] as num).toInt());
      });
    } catch (e) {
      print("❌ เกิดข้อผิดพลาดขณะดึงข้อมูลจาก Firebase: $e");
    }
  }

  // Computed properties
  double get bmi => (weight == 0 || height == 0) ? 0.0 : weight / ((height / 100) * (height / 100));
  String get healthAdvice => bmi < 18.5 ? "ควรรับประทานอาหารให้ครบ 5 หมู่" 
      : bmi <= 24.9 ? "รักษาสมดุลอาหารและออกกำลังกาย" : "ควรควบคุมอาหารและออกกำลังกาย";
  String get bmiImage => 'assets/bmi/${gender == "ชาย" ? "man" : "girl"}_${_getBmiRange()}.png';
  
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
        child: Column(children: [
          _buildHeader(),
          _buildWeekDays(),
          _buildHealthInfo(),
          _buildWeightGoal(),
          _buildFoodRecommendation(),
        ]),
      ),
      bottomNavigationBar: _buildNavigation(),
    );
  }

  Widget _buildContainer({required Widget child, EdgeInsets? margin, EdgeInsets? padding}) {
    return Container(
      margin: margin ?? EdgeInsets.all(25),
      padding: padding ?? EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 30, spreadRadius: 20)],
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
      child: Row(children: [
        Image.asset(bmiImage, width: 110, height: 222, fit: BoxFit.cover),
        SizedBox(width: 15),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("ข้อมูลสุขภาพ คุณ$username", 
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, 
                    color: Color.fromARGB(255, 70, 51, 43))),
            Text("ค่า BMI ของคุณ: ${bmi.toStringAsFixed(1)}", 
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, 
                    color: Color.fromARGB(255, 84, 69, 53))),
            Text(healthAdvice, style: TextStyle(fontSize: 10, color: Color.fromARGB(255, 70, 51, 43))),
            SizedBox(height: 15),
            _buildProgressBar(
              consumedCalories / calorieGoal,
              color: consumedCalories >= calorieGoal ? Colors.red : Color.fromARGB(255, 70, 51, 43),
              height: 35,
            ),
            SizedBox(height: 10),
            Center(child: Text("$consumedCalories / $calorieGoal kcal", 
                style: TextStyle(fontSize: 14, color: Colors.black))),
            if (foodHistory.isNotEmpty) _buildFoodList(),
          ],
        )),
      ]),
    );
  }

  Widget _buildFoodList() {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("อาหารที่กินวันนี้", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          ...foodHistory.map((food) => Text(
            "${food["food"]} (${food["calories"]} kcal)",
            style: TextStyle(fontSize: 9, color: Colors.black),
          )),
        ],
      ),
    );
  }

  Widget _buildWeightGoal() {
    double? progressValue = 0;
    if (startWeight != 0 && targetWeight != 0 && weight != 0) {
      double totalDiff = (targetWeight - startWeight).abs();
      double currentDiff = (weight - targetWeight).abs();
      progressValue = (totalDiff == 0 ? 1 : (1 - (currentDiff / totalDiff))).clamp(0, 1) as double?;
    }
    int percentage = (progressValue! * 100).round();

    return _buildContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("เป้าหมายน้ำหนัก", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          Text("ปัจจุบัน: ${weight.toStringAsFixed(1)} kg", style: TextStyle(fontSize: 14)),
          Text("เป้าหมาย: ${targetWeight.toStringAsFixed(1)} kg", style: TextStyle(fontSize: 14)),
          SizedBox(height: 15),
          _buildProgressBar(progressValue, 
              color: percentage >= 100 ? Colors.green : Color.fromARGB(255, 47, 130, 174)),
          SizedBox(height: 10),
          Text("$percentage% สำเร็จ", 
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, 
                  color: percentage >= 100 ? Colors.green : Colors.black)),
        ],
      ),
    );
  }

  Widget _buildFoodRecommendation() {
    final foodMenu = [
      {"name": "ข้าวผัด", "image": "https://images.unsplash.com/photo-1603133872878-684f208fb84b?w=400&h=300&fit=crop"},
      {"name": "ราเมง", "image": "https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=400&h=300&fit=crop"},
      {"name": "กล้วย", "image": "https://images.unsplash.com/photo-1574226516831-e1dff420e562?w=400&h=300&fit=crop"},
      {"name": "ไก่ทอด", "image": "https://images.unsplash.com/photo-1562967914-608f82629710?w=400&h=300&fit=crop"},
      {"name": "แฮมเบอร์เกอร์", "image": "https://images.unsplash.com/photo-1586190848861-99aa4a171e90?w=400&h=300&fit=crop"},
    ];

    return _buildContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("แนะนำเมนูอาหาร", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 15),
          Container(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: foodMenu.length,
              itemBuilder: (context, index) => Container(
                width: 150,
                margin: EdgeInsets.only(right: 15),
                child: Column(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.network(
                      foodMenu[index]["image"]!,
                      width: 150, height: 130,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 150, height: 130,
                        color: Colors.grey[300],
                        child: Icon(Icons.food_bank, color: Colors.grey, size: 40),
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(foodMenu[index]["name"]!, 
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center, maxLines: 2),
                ]),
              ),
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
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen())),
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
    bool isToday = date.day == today.day && date.month == today.month && date.year == today.year;
    return Container(
      alignment: Alignment.center,
      width: 50, height: 70,
      decoration: BoxDecoration(
        color: isToday ? Color.fromARGB(255, 70, 51, 43) : Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.grey),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(thaiWeekDays[date.weekday] ?? "", 
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, 
                  color: isToday ? Colors.white : Colors.black)),
          Text("${date.day}", 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, 
                  color: isToday ? Colors.white : Colors.black)),
        ],
      ),
    );
  }

  Widget _buildNavigation() {
    return CrystalNavigationBar(
      onTap: (index) {
        setState(() => currentIndex = index);
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => [ScanFoodScreen(), FoodHistoryScreen(), ProfileScreen()][index],
        ));
      },
      backgroundColor: Color.fromARGB(255, 70, 51, 43),
      currentIndex: currentIndex,
      items: [Icons.camera_alt, Icons.history, Icons.person]
          .map((icon) => CrystalNavigationBarItem(
                icon: icon,
                unselectedColor: Colors.white,
                selectedColor: Colors.white,
              ))
          .toList(),
    );
  }
}