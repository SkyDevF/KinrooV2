import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_provider.dart';
import '../providers/food_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/food_menu_provider.dart';
import 'profile_screen.dart';
import 'food_history_screen.dart';
import 'scan_food_screen.dart';
import 'package:crystal_navigation_bar/crystal_navigation_bar.dart';
import 'update_weight_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

// This widget serves as the main home screen of the app, displaying user health data, food history, and navigation options.
class _HomeScreenState extends ConsumerState<HomeScreen> {
  double startWeight = 75.0;
  PageController _pageController = PageController();
  Timer? _autoScrollTimer;
  int _currentFoodIndex = 0;

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
    _checkForNewDay();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(Duration(seconds: 3), (timer) {
      final recommendedFood = ref.read(recommendedFoodProvider);
      if (recommendedFood.isNotEmpty) {
        _currentFoodIndex = (_currentFoodIndex + 1) % recommendedFood.length;
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            _currentFoodIndex,
            duration: Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  void _checkForNewDay() async {
    final foodService = ref.read(foodServiceProvider);
    await foodService.checkForNewDay();
  }

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final foodHistoryAsync = ref.watch(foodHistoryProvider);
    final consumedCalories = ref.watch(consumedCaloriesProvider);
    final bmi = ref.watch(bmiProvider);
    final healthAdvice = ref.watch(healthAdviceProvider);
    final bmiImage = ref.watch(bmiImageProvider);
    final weekDays = ref.watch(weekDaysProvider);
    final currentIndex = ref.watch(navigationIndexProvider);
    final today = ref.watch(currentDateProvider);

    return Scaffold(
      backgroundColor: Color.fromARGB(255, 47, 130, 174),
      body: userProfileAsync.when(
        data: (userProfile) => SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(),
              _buildWeekDays(weekDays, today),
              _buildHealthInfo(
                userProfile,
                consumedCalories,
                bmi,
                healthAdvice,
                bmiImage,
                foodHistoryAsync,
              ),
              _buildFoodRecommendation(bmi),
              _buildWeightGoal(userProfile),
            ],
          ),
        ),
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('เกิดข้อผิดพลาด: $error')),
      ),
      bottomNavigationBar: _buildNavigation(currentIndex),
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

  Widget _buildHealthInfo(
    UserProfile? userProfile,
    int consumedCalories,
    double bmi,
    String healthAdvice,
    String bmiImage,
    AsyncValue<List<FoodItem>> foodHistoryAsync,
  ) {
    if (userProfile == null) return SizedBox.shrink();

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
                  "ข้อมูลสุขภาพ คุณ${userProfile.name}",
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
                  consumedCalories / userProfile.dailyCalories,
                  color: consumedCalories >= userProfile.dailyCalories
                      ? Colors.red
                      : Color.fromARGB(255, 70, 51, 43),
                  height: 35,
                ),
                SizedBox(height: 10),
                Center(
                  child: Text(
                    "$consumedCalories / ${userProfile.dailyCalories} kcal",
                    style: TextStyle(fontSize: 14, color: Colors.black),
                  ),
                ),
                foodHistoryAsync.when(
                  data: (foodHistory) => foodHistory.isNotEmpty
                      ? _buildFoodList(foodHistory)
                      : SizedBox.shrink(),
                  loading: () => SizedBox.shrink(),
                  error: (_, __) => SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodList(List<FoodItem> foodHistory) {
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
              "${food.food} (${food.calories} kcal)",
              style: TextStyle(fontSize: 9, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodRecommendation(double bmi) {
    final recommendedFood = ref.watch(recommendedFoodProvider);

    return Container(
      margin: EdgeInsets.all(25),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "แนะนำเมนูอาหาร",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 15),
          Container(
            height: 170,
            child: recommendedFood.isEmpty
                ? Center(
                    child: Text(
                      "ไม่พบเมนูที่เหมาะสมกับสุขภาพของคุณ",
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                : PageView.builder(
                    controller: _pageController,
                    itemCount: recommendedFood.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentFoodIndex = index;
                      });
                    },
                    itemBuilder: (ctx, index) {
                      final item = recommendedFood[index];

                      return Container(
                        width: double.infinity,
                        margin: EdgeInsets.symmetric(horizontal: 5),
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: item.image.startsWith("assets/")
                                  ? Image.asset(
                                      item.image,
                                      width: double.infinity,
                                      height: 110,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.network(
                                      item.image,
                                      width: double.infinity,
                                      height: 130,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (c, child, progress) {
                                        if (progress == null) return child;
                                        return Container(
                                          width: double.infinity,
                                          height: 130,
                                          child: Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        );
                                      },
                                      errorBuilder: (_, __, ___) => Container(
                                        width: double.infinity,
                                        height: 130,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[300],
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.image_not_supported,
                                          size: 40,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              item.name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              "${item.calories} kcal",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          if (recommendedFood.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                recommendedFood.length,
                (index) => Container(
                  width: 8,
                  height: 8,
                  margin: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentFoodIndex == index
                        ? Colors.white
                        : Colors.white.withOpacity(0.4),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWeightGoal(UserProfile? userProfile) {
    if (userProfile == null) return SizedBox.shrink();

    double? progressValue = 0;
    if (startWeight != 0 &&
        userProfile.targetWeight != 0 &&
        userProfile.weight != 0) {
      double totalDiff = (userProfile.targetWeight - startWeight)
          .abs()
          .toDouble();
      double currentDiff = (userProfile.weight - userProfile.targetWeight)
          .abs()
          .toDouble();
      progressValue = (totalDiff == 0 ? 1.0 : (1.0 - (currentDiff / totalDiff)))
          .clamp(0.0, 1.0);
    }
    int percentage = (progressValue * 100).round();

    return _buildContainer(
      child: Stack(
        children: [
          // กล่องเนื้อหาเป้าหมายน้ำหนัก
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "เป้าหมายน้ำหนัก",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                "ปัจจุบัน: ${userProfile.weight.toStringAsFixed(1)} kg",
                style: TextStyle(fontSize: 14),
              ),
              Text(
                "เป้าหมาย: ${userProfile.targetWeight.toStringAsFixed(1)} kg",
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 15),
              _buildProgressBar(
                progressValue,
                color: percentage >= 100
                    ? Colors.green
                    : Color.fromARGB(255, 70, 51, 43),
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

          // ปุ่มอัปเดตน้ำหนัก (มุมขวาบน)
          Positioned(
            top: 0,
            right: 0,
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 70, 51, 43), // สี brown
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => UpdateWeightScreen()),
                );
              },
              child: Text(
                "อัปเดต",
                style: TextStyle(color: Colors.white, fontSize: 12),
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
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ProfileScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekDays(List<DateTime> weekDays, DateTime today) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 15,
            spreadRadius: 2,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: weekDays
            .map((date) => _weekDayContainer(date, today))
            .toList(),
      ),
    );
  }

  Widget _weekDayContainer(DateTime date, DateTime today) {
    bool isToday =
        date.day == today.day &&
        date.month == today.month &&
        date.year == today.year;

    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      alignment: Alignment.center,
      width: 42,
      height: 65,
      decoration: BoxDecoration(
        gradient: isToday
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.fromARGB(255, 70, 51, 43),
                  Color.fromARGB(255, 90, 71, 63),
                ],
              )
            : LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.grey[50]!, Colors.grey[100]!],
              ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: isToday
            ? [
                BoxShadow(
                  color: Color.fromARGB(255, 70, 51, 43).withValues(alpha: 0.4),
                  blurRadius: 8,
                  spreadRadius: 1,
                  offset: Offset(0, 3),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.2),
                  blurRadius: 4,
                  spreadRadius: 0,
                  offset: Offset(0, 2),
                ),
              ],
        border: isToday
            ? null
            : Border.all(color: Colors.grey.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            thaiWeekDays[date.weekday] ?? "",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isToday ? Colors.white : Colors.grey[600],
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 4),
          Text(
            "${date.day}",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isToday ? Colors.white : Color.fromARGB(255, 70, 51, 43),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigation(int currentIndex) {
    return CrystalNavigationBar(
      onTap: (index) {
        ref.read(navigationIndexProvider.notifier).state = index;
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
