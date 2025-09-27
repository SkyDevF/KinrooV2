import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/user_provider.dart';

// Enhanced Food Item Model
class FoodHistoryItem {
  final String id;
  final String name;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final DateTime timestamp;

  FoodHistoryItem({
    required this.id,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.timestamp,
  });

  factory FoodHistoryItem.fromFirestore(
    String docId,
    Map<String, dynamic> data,
  ) {
    return FoodHistoryItem(
      id: docId,
      name: data['food'] ?? 'อาหารไม่ระบุชื่อ',
      calories: (data['calories'] as num?)?.toInt() ?? 0,
      protein: (data['protein'] as num?)?.toInt() ?? 0,
      carbs: (data['carbs'] as num?)?.toInt() ?? 0,
      fat: (data['fat'] as num?)?.toInt() ?? 0,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

// Daily Nutrition Summary
class DailyNutrition {
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final int targetCalories;
  final int targetProtein;
  final int targetCarbs;
  final int targetFat;

  DailyNutrition({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.targetCalories,
    required this.targetProtein,
    required this.targetCarbs,
    required this.targetFat,
  });

  int get caloriesDifference => calories - targetCalories;
  bool get isOverCalories => caloriesDifference > 0;
  bool get isUnderCalories => caloriesDifference < 0;
}

// Providers for Food History Screen
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

final foodHistoryForDateProvider =
    StreamProvider.family<List<FoodHistoryItem>, DateTime>((ref, date) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return Stream.value([]);

      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      return FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('food_history')
          .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
          .where('timestamp', isLessThanOrEqualTo: endOfDay)
          .orderBy('timestamp', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => FoodHistoryItem.fromFirestore(doc.id, doc.data()))
                .toList(),
          );
    });

final dailyNutritionProvider = Provider.family<DailyNutrition, DateTime>((
  ref,
  date,
) {
  final userProfile = ref.watch(userProfileProvider).value;
  final foodHistory = ref.watch(foodHistoryForDateProvider(date)).value ?? [];

  final targetCalories = userProfile?.dailyCalories ?? 2000;
  final targetProtein = ((targetCalories * 0.15 / 4).round()).toInt();
  final targetCarbs = ((targetCalories * 0.55 / 4).round()).toInt();
  final targetFat = ((targetCalories * 0.30 / 9).round()).toInt();

  final totalCalories = foodHistory.fold(
    0,
    (total, food) => total + food.calories,
  );
  final totalProtein = foodHistory.fold(
    0,
    (total, food) => total + food.protein,
  );
  final totalCarbs = foodHistory.fold(0, (total, food) => total + food.carbs);
  final totalFat = foodHistory.fold(0, (total, food) => total + food.fat);

  return DailyNutrition(
    calories: totalCalories,
    protein: totalProtein,
    carbs: totalCarbs,
    fat: totalFat,
    targetCalories: targetCalories,
    targetProtein: targetProtein,
    targetCarbs: targetCarbs,
    targetFat: targetFat,
  );
});

// ปรับปรุง Weekly Nutrition Provider ให้ใช้งานได้จริง
final weeklyNutritionProvider = FutureProvider.autoDispose<Map<String, int>>((
  ref,
) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return {
      'totalCalories': 0,
      'overCalories': 0,
      'underCalories': 0,
      'avgCalories': 0,
      'daysWithData': 0,
    };
  }

  final userProfile = ref.watch(userProfileProvider).value;
  final targetCalories = userProfile?.dailyCalories ?? 2000;

  final today = DateTime.now();
  final startDate = DateTime(
    today.year,
    today.month,
    today.day,
  ).subtract(const Duration(days: 6));
  final endDate = DateTime(today.year, today.month, today.day, 23, 59, 59);

  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('food_history')
        .where('timestamp', isGreaterThanOrEqualTo: startDate)
        .where('timestamp', isLessThanOrEqualTo: endDate)
        .get();

    // จัดกลุ่มข้อมูลตามวัน
    Map<String, List<FoodHistoryItem>> dailyFoods = {};
    for (var doc in snapshot.docs) {
      final food = FoodHistoryItem.fromFirestore(doc.id, doc.data());
      final dateKey =
          '${food.timestamp.year}-${food.timestamp.month.toString().padLeft(2, '0')}-${food.timestamp.day.toString().padLeft(2, '0')}';
      dailyFoods[dateKey] = (dailyFoods[dateKey] ?? [])..add(food);
    }

    int totalCalories = 0;
    int totalOverCalories = 0;
    int totalUnderCalories = 0;
    int daysWithData = 0;

    // คำนวณสำหรับแต่ละวัน (7 วันย้อนหลัง)
    for (int i = 0; i < 7; i++) {
      final date = today.subtract(Duration(days: i));
      final dateKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final dayFoods = dailyFoods[dateKey] ?? [];

      final dayCalories = dayFoods.fold(
        0,
        (total, food) => total + food.calories,
      );

      if (dayFoods.isNotEmpty) {
        daysWithData++;
      }

      totalCalories += dayCalories;

      final difference = dayCalories - targetCalories;
      if (difference > 0) {
        totalOverCalories += difference;
      } else if (difference < 0 && dayFoods.isNotEmpty) {
        totalUnderCalories += difference.abs();
      }
    }

    final avgCalories = daysWithData > 0 ? (totalCalories / 7).round() : 0;

    return {
      'totalCalories': totalCalories,
      'overCalories': totalOverCalories,
      'underCalories': totalUnderCalories,
      'avgCalories': avgCalories,
      'daysWithData': daysWithData,
    };
  } catch (e) {
    print('Error in weeklyNutritionProvider: $e');
    return {
      'totalCalories': 0,
      'overCalories': 0,
      'underCalories': 0,
      'avgCalories': 0,
      'daysWithData': 0,
    };
  }
});

// ปรับปรุง Monthly Nutrition Provider ให้ใช้งานได้จริง
final monthlyNutritionProvider = FutureProvider.autoDispose<Map<String, int>>((
  ref,
) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return {
      'totalCalories': 0,
      'overCalories': 0,
      'underCalories': 0,
      'avgCalories': 0,
      'daysWithData': 0,
    };
  }

  final userProfile = ref.watch(userProfileProvider).value;
  final targetCalories = userProfile?.dailyCalories ?? 2000;

  final today = DateTime.now();
  final startDate = DateTime(
    today.year,
    today.month,
    today.day,
  ).subtract(const Duration(days: 29));
  final endDate = DateTime(today.year, today.month, today.day, 23, 59, 59);

  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('food_history')
        .where('timestamp', isGreaterThanOrEqualTo: startDate)
        .where('timestamp', isLessThanOrEqualTo: endDate)
        .get();

    // จัดกลุ่มข้อมูลตามวัน
    Map<String, List<FoodHistoryItem>> dailyFoods = {};
    for (var doc in snapshot.docs) {
      final food = FoodHistoryItem.fromFirestore(doc.id, doc.data());
      final dateKey =
          '${food.timestamp.year}-${food.timestamp.month.toString().padLeft(2, '0')}-${food.timestamp.day.toString().padLeft(2, '0')}';
      dailyFoods[dateKey] = (dailyFoods[dateKey] ?? [])..add(food);
    }

    int totalCalories = 0;
    int totalOverCalories = 0;
    int totalUnderCalories = 0;
    int daysWithData = 0;

    // คำนวณสำหรับแต่ละวัน (30 วันย้อนหลัง)
    for (int i = 0; i < 30; i++) {
      final date = today.subtract(Duration(days: i));
      final dateKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final dayFoods = dailyFoods[dateKey] ?? [];

      final dayCalories = dayFoods.fold(
        0,
        (total, food) => total + food.calories,
      );

      if (dayFoods.isNotEmpty) {
        daysWithData++;
      }

      totalCalories += dayCalories;

      final difference = dayCalories - targetCalories;
      if (difference > 0) {
        totalOverCalories += difference;
      } else if (difference < 0 && dayFoods.isNotEmpty) {
        totalUnderCalories += difference.abs();
      }
    }

    final avgCalories = daysWithData > 0 ? (totalCalories / 30).round() : 0;

    return {
      'totalCalories': totalCalories,
      'overCalories': totalOverCalories,
      'underCalories': totalUnderCalories,
      'avgCalories': avgCalories,
      'daysWithData': daysWithData,
    };
  } catch (e) {
    print('Error in monthlyNutritionProvider: $e');
    return {
      'totalCalories': 0,
      'overCalories': 0,
      'underCalories': 0,
      'avgCalories': 0,
      'daysWithData': 0,
    };
  }
});

class FoodHistoryScreen extends ConsumerStatefulWidget {
  const FoodHistoryScreen({super.key});

  @override
  ConsumerState<FoodHistoryScreen> createState() => _FoodHistoryScreenState();
}

class _FoodHistoryScreenState extends ConsumerState<FoodHistoryScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();

  // Delete food item function
  Future<void> _deleteFoodItem(String foodId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('food_history')
          .doc(foodId)
          .delete();

      // Refresh providers to update the UI
      ref.invalidate(foodHistoryForDateProvider);
      ref.invalidate(weeklyNutritionProvider);
      ref.invalidate(monthlyNutritionProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ลบรายการอาหารเรียบร้อยแล้ว'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการลบรายการอาหาร: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedDateProvider);
    final dailyNutrition = ref.watch(dailyNutritionProvider(selectedDate));
    final foodHistory = ref.watch(foodHistoryForDateProvider(selectedDate));
    final weeklyNutritionAsync = ref.watch(weeklyNutritionProvider);
    final monthlyNutritionAsync = ref.watch(monthlyNutritionProvider);

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 47, 130, 174),
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh all providers when user pulls to refresh
          ref.invalidate(weeklyNutritionProvider);
          ref.invalidate(monthlyNutritionProvider);
          ref.invalidate(foodHistoryForDateProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildCalendarBox(),
              const SizedBox(height: 16),
              _buildNutritionSummaryCards(
                weeklyNutritionAsync,
                monthlyNutritionAsync,
              ),
              const SizedBox(height: 16),
              _buildDailyNutritionBox(dailyNutrition),
              const SizedBox(height: 16),
              _buildCaloriesProgressBox(dailyNutrition),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildPieChartBox(
                      'โปรตีน',
                      dailyNutrition.protein,
                      dailyNutrition.targetProtein,
                      Colors.red,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildPieChartBox(
                      'คาร์โบไฮเดรต',
                      dailyNutrition.carbs,
                      dailyNutrition.targetCarbs,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildPieChartBox(
                'ไขมัน',
                dailyNutrition.fat,
                dailyNutrition.targetFat,
                Colors.yellow,
              ),
              const SizedBox(height: 16),
              _buildCardWrapper(
                title: 'รายการอาหารที่บันทึกสำหรับวันที่เลือก',
                child: foodHistory.when(
                  data: (foods) => _buildFoodListInMainScreen(foods),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) =>
                      Center(child: Text('เกิดข้อผิดพลาด: $error')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Image.asset('assets/icon/logo.png', width: 150, height: 100),
      centerTitle: true,
      backgroundColor: const Color.fromARGB(255, 70, 51, 43),
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
    );
  }

  // ปรับปรุงการแสดงผลสรุป 7 วัน และ 30 วัน
  Widget _buildNutritionSummaryCards(
    AsyncValue<Map<String, int>> weeklyNutritionAsync,
    AsyncValue<Map<String, int>> monthlyNutritionAsync,
  ) {
    return Row(
      children: [
        Expanded(
          child: weeklyNutritionAsync.when(
            data: (weeklyNutrition) => _buildSummaryCard(
              title: 'สรุป 7 วัน',
              totalCalories: weeklyNutrition['totalCalories'] ?? 0,
              overCalories: weeklyNutrition['overCalories'] ?? 0,
              underCalories: weeklyNutrition['underCalories'] ?? 0,
              avgCalories: weeklyNutrition['avgCalories'] ?? 0,
              daysWithData: weeklyNutrition['daysWithData'] ?? 0,
              color: Colors.blue,
            ),
            loading: () => _buildLoadingSummaryCard('สรุป 7 วัน', Colors.blue),
            error: (error, stack) => _buildErrorSummaryCard(
              'สรุป 7 วัน',
              Colors.blue,
              error.toString(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: monthlyNutritionAsync.when(
            data: (monthlyNutrition) => _buildSummaryCard(
              title: 'สรุป 30 วัน',
              totalCalories: monthlyNutrition['totalCalories'] ?? 0,
              overCalories: monthlyNutrition['overCalories'] ?? 0,
              underCalories: monthlyNutrition['underCalories'] ?? 0,
              avgCalories: monthlyNutrition['avgCalories'] ?? 0,
              daysWithData: monthlyNutrition['daysWithData'] ?? 0,
              color: Colors.purple,
            ),
            loading: () =>
                _buildLoadingSummaryCard('สรุป 30 วัน', Colors.purple),
            error: (error, stack) => _buildErrorSummaryCard(
              'สรุป 30 วัน',
              Colors.purple,
              error.toString(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required int totalCalories,
    required int overCalories,
    required int underCalories,
    required int avgCalories,
    required int daysWithData,
    required Color color,
  }) {
    return _buildCardWrapper(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'รวม: ${_formatNumber(totalCalories)} kcal',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'เฉลี่ย: ${_formatNumber(avgCalories)} kcal/วัน',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          const SizedBox(height: 2),
          Text(
            'กินเกิน: ${_formatNumber(overCalories)} kcal',
            style: TextStyle(color: Colors.red[300], fontSize: 11),
          ),
          const SizedBox(height: 2),
          Text(
            'กินขาด: ${_formatNumber(underCalories)} kcal',
            style: TextStyle(color: Colors.orange[300], fontSize: 11),
          ),
          const SizedBox(height: 2),
          Text(
            'มีข้อมูล: $daysWithData วัน',
            style: const TextStyle(color: Colors.white60, fontSize: 10),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }

  Widget _buildLoadingSummaryCard(String title, Color color) {
    return _buildCardWrapper(
      title: title,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'กำลังโหลดข้อมูล...',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          SizedBox(height: 8),
          Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorSummaryCard(String title, Color color, String error) {
    return _buildCardWrapper(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'เกิดข้อผิดพลาด',
            style: TextStyle(color: Colors.red, fontSize: 12),
          ),
          const SizedBox(height: 4),
          const Text(
            'ไม่สามารถโหลดข้อมูลได้',
            style: TextStyle(color: Colors.white70, fontSize: 11),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () {
              // Retry loading data
              ref.invalidate(weeklyNutritionProvider);
              ref.invalidate(monthlyNutritionProvider);
            },
            child: const Text(
              'แตะเพื่อลองใหม่',
              style: TextStyle(
                color: Colors.blue,
                fontSize: 10,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardWrapper({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildCalendarBox() {
    return _buildCardWrapper(
      title: 'ปฏิทินการกิน',
      child: TableCalendar<FoodHistoryItem>(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) =>
            isSameDay(ref.watch(selectedDateProvider), day),
        onDaySelected: (selectedDay, focusedDay) {
          ref.read(selectedDateProvider.notifier).state = selectedDay;
          setState(() => _focusedDay = focusedDay);
          _showDayDetailDialog(selectedDay);
        },
        onFormatChanged: (format) => setState(() => _calendarFormat = format),
        calendarStyle: const CalendarStyle(
          outsideDaysVisible: false,
          todayDecoration: BoxDecoration(
            color: Color(0xFFE94560),
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: Color.fromARGB(255, 47, 130, 174),
            shape: BoxShape.circle,
          ),
          defaultTextStyle: TextStyle(color: Colors.white),
          todayTextStyle: TextStyle(color: Colors.white),
          selectedTextStyle: TextStyle(color: Colors.white),
        ),
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 16),
          leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
          rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
        ),
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(color: Colors.white70),
          weekendStyle: TextStyle(color: Colors.white70),
        ),
      ),
    );
  }

  Widget _buildDailyNutritionBox(DailyNutrition nutrition) {
    return _buildCardWrapper(
      title: 'พลังงานในวันที่เลือก',
      child: Container(
        height: 200,
        padding: const EdgeInsets.all(16),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceEvenly,
            maxY: _getMaxValue(nutrition),
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (group) => Colors.black87,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final titles = ['แคลลอรี่', 'โปรตีน', 'คาร์บ', 'ไขมัน'];
                  final values = [
                    nutrition.calories,
                    nutrition.protein,
                    nutrition.carbs,
                    nutrition.fat,
                  ];
                  return BarTooltipItem(
                    '${titles[group.x]}\n${values[group.x]}',
                    const TextStyle(color: Colors.white, fontSize: 12),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    const titles = ['Calories', 'Proteins', 'Carbs', 'Fat'];
                    if (value.toInt() >= 0 && value.toInt() < titles.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          titles[value.toInt()],
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            barGroups: [
              _buildNutritionBarData(
                0,
                nutrition.calories.toDouble(),
                const Color(0xFF4A90E2),
              ),
              _buildNutritionBarData(
                1,
                nutrition.protein.toDouble(),
                const Color(0xFF4A90E2),
              ),
              _buildNutritionBarData(
                2,
                nutrition.carbs.toDouble(),
                const Color(0xFF4A90E2),
              ),
              _buildNutritionBarData(
                3,
                nutrition.fat.toDouble(),
                const Color(0xFF4A90E2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BarChartGroupData _buildNutritionBarData(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 24,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
          backDrawRodData: BackgroundBarChartRodData(show: false),
        ),
      ],
    );
  }

  double _getMaxValue(DailyNutrition nutrition) {
    final values = [
      nutrition.calories.toDouble(),
      nutrition.protein.toDouble(),
      nutrition.carbs.toDouble(),
      nutrition.fat.toDouble(),
    ];

    final maxValue = values.reduce((a, b) => a > b ? a : b);
    return maxValue * 1.2;
  }

  Widget _buildCaloriesProgressBox(DailyNutrition nutrition) {
    double progress = (nutrition.targetCalories > 0)
        ? nutrition.calories / nutrition.targetCalories
        : 0.0;

    if (progress > 1.0) progress = 1.0;

    int remainingCalories = nutrition.targetCalories - nutrition.calories;
    if (remainingCalories < 0) remainingCalories = 0;

    return _buildCardWrapper(
      title: 'แคลลอรี่ต่อวัน',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(15),
            ),
            child: Stack(
              children: [
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    height: 30,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color.fromARGB(255, 38, 241, 16),
                          Color.fromARGB(255, 8, 101, 27),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    '${nutrition.calories} / ${nutrition.targetCalories} kcal',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'เหลือ: $remainingCalories kcal',
            style: const TextStyle(color: Colors.white70),
          ),
          if (nutrition.isOverCalories)
            Text(
              'กินเกิน: ${nutrition.caloriesDifference} kcal',
              style: const TextStyle(color: Colors.red),
            ),
          if (nutrition.isUnderCalories)
            Text(
              'กินขาด: ${nutrition.caloriesDifference.abs()} kcal',
              style: const TextStyle(color: Colors.orange),
            ),
        ],
      ),
    );
  }

  Widget _buildPieChartBox(
    String title,
    int consumed,
    int target,
    Color color,
  ) {
    double consumedValue = consumed.toDouble();
    double targetValue = target.toDouble();
    double remainingValue = (target - consumed).toDouble();

    if (remainingValue < 0) {
      remainingValue = 0;
      consumedValue = targetValue > 0 ? targetValue : 0;
    }

    if (targetValue == 0) {
      consumedValue = 0;
      remainingValue = 0;
    }

    return _buildCardWrapper(
      title: title,
      child: Column(
        children: [
          SizedBox(
            height: 100,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    color: color,
                    value: consumedValue,
                    title: '${consumed}g',
                    radius: 40,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    color: Colors.grey[700],
                    value: remainingValue,
                    title: '${target - consumed}g',
                    radius: 40,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
                centerSpaceRadius: 20,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildPieChartLegend('กิน: ${consumed}g', color),
          const SizedBox(height: 4),
          _buildPieChartLegend(
            'เหลือ: ${target - consumed}g',
            Colors.grey[700]!,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildPieChartLegend(String text, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }

  Widget _buildFoodListInMainScreen(List<FoodHistoryItem> foods) {
    if (foods.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Text(
            'ยังไม่มีข้อมูลอาหารสำหรับวันที่เลือก',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: foods.length,
      itemBuilder: (context, index) {
        var food = foods[index];
        String timeString =
            '${food.timestamp.hour.toString().padLeft(2, '0')}:${food.timestamp.minute.toString().padLeft(2, '0')}';

        return Card(
          color: const Color(0xFF1A1A2E),
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            title: Text(
              food.name,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'เวลา: $timeString',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
                Text(
                  'แคลลอรี่: ${food.calories} kcal',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'P:${food.protein}g',
                      style: TextStyle(color: Colors.red[300], fontSize: 10),
                    ),
                    Text(
                      'C:${food.carbs}g',
                      style: TextStyle(color: Colors.orange[300], fontSize: 10),
                    ),
                    Text(
                      'F:${food.fat}g',
                      style: TextStyle(color: Colors.yellow[300], fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: () => _showDeleteConfirmDialog(food),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDeleteConfirmDialog(FoodHistoryItem food) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F3460),
        title: const Text('ยืนยันการลบ', style: TextStyle(color: Colors.white)),
        content: Text(
          'คุณต้องการลบ "${food.name}" หรือไม่?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'ยกเลิก',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteFoodItem(food.id);
            },
            child: const Text('ลบ', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDayDetailDialog(DateTime selectedDay) {
    final dailyNutrition = ref.read(dailyNutritionProvider(selectedDay));
    final foodHistoryAsync = ref.read(foodHistoryForDateProvider(selectedDay));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F3460),
        title: Text(
          'รายละเอียดวันที่ ${selectedDay.day}/${selectedDay.month}/${selectedDay.year}',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildNutritionSummary(dailyNutrition),
              const SizedBox(height: 16),
              const Text(
                'รายการอาหาร',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              foodHistoryAsync.when(
                data: (foods) => _buildFoodListInDialog(foods),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Text(
                    'เกิดข้อผิดพลาด: $error',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ปิด', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionSummary(DailyNutrition nutrition) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'สรุปสารอาหาร',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'แคลลอรี่รวม: ${nutrition.calories} kcal',
            style: const TextStyle(color: Colors.white70),
          ),
          Text(
            'โปรตีน: ${nutrition.protein}g',
            style: TextStyle(color: Colors.red[300]),
          ),
          Text(
            'คาร์โบไฮเดรต: ${nutrition.carbs}g',
            style: TextStyle(color: Colors.orange[300]),
          ),
          Text(
            'ไขมัน: ${nutrition.fat}g',
            style: TextStyle(color: Colors.yellow[300]),
          ),
          if (nutrition.isOverCalories)
            Text(
              'กินเกิน: ${nutrition.caloriesDifference} kcal',
              style: const TextStyle(color: Colors.red),
            ),
          if (nutrition.isUnderCalories)
            Text(
              'กินขาด: ${nutrition.caloriesDifference.abs()} kcal',
              style: const TextStyle(color: Colors.orange),
            ),
        ],
      ),
    );
  }

  Widget _buildFoodListInDialog(List<FoodHistoryItem> foods) {
    if (foods.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'ไม่มีข้อมูลอาหารในวันนี้',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }
    return SizedBox(
      height: 200,
      child: ListView.builder(
        itemCount: foods.length,
        itemBuilder: (context, index) {
          var food = foods[index];
          String timeString =
              '${food.timestamp.hour.toString().padLeft(2, '0')}:${food.timestamp.minute.toString().padLeft(2, '0')}';

          return Card(
            color: const Color(0xFF1A1A2E),
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              title: Text(
                food.name,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'เวลา: $timeString',
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                  Text(
                    'แคลลอรี่: ${food.calories} kcal',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'P:${food.protein}g',
                    style: TextStyle(color: Colors.red[300], fontSize: 10),
                  ),
                  Text(
                    'C:${food.carbs}g',
                    style: TextStyle(color: Colors.orange[300], fontSize: 10),
                  ),
                  Text(
                    'F:${food.fat}g',
                    style: TextStyle(color: Colors.yellow[300], fontSize: 10),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
