import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FoodHistoryScreen extends StatefulWidget {
  const FoodHistoryScreen({super.key});

  @override
  _FoodHistoryScreenState createState() => _FoodHistoryScreenState();
}

class _FoodHistoryScreenState extends State<FoodHistoryScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Map<String, dynamic> userProfile = {};
  Map<String, dynamic> dailyNutrition = {
    'calories': 0,
    'protein': 0,
    'carbs': 0,
    'fat': 0,
    'targetCalories': 2000,
    'targetProtein': 150,
    'targetCarbs': 250,
    'targetFat': 70,
  };
  List<Map<String, dynamic>> todayFoods = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  // --- Functions for Data Loading ---

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      await Future.wait([
        _loadUserData(),
        _updateDailyNutrition(_focusedDay), // โหลดข้อมูลอาหารสำหรับวันที่เลือก (เริ่มต้นคือวันนี้)
      ]);
    } catch (e) {
      print('Error in _loadData: $e');
      // อาจจะแสดง SnackBar หรือข้อความ error ให้ผู้ใช้ทราบ
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _loadUserData() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        print('User not logged in.');
        return;
      }

      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists && mounted) {
        setState(() {
          userProfile = userDoc.data() as Map<String, dynamic>;
          dailyNutrition['targetCalories'] = userProfile['daily_calories'] as int? ?? 2000;

          dailyNutrition['targetProtein'] = ((dailyNutrition['targetCalories'] * 0.15 / 4).round()).toInt();
          dailyNutrition['targetCarbs'] = ((dailyNutrition['targetCalories'] * 0.55 / 4).round()).toInt();
          dailyNutrition['targetFat'] = ((dailyNutrition['targetCalories'] * 0.30 / 9).round()).toInt();

          dailyNutrition['targetProtein'] = dailyNutrition['targetProtein'] < 0 ? 0 : dailyNutrition['targetProtein'];
          dailyNutrition['targetCarbs'] = dailyNutrition['targetCarbs'] < 0 ? 0 : dailyNutrition['targetCarbs'];
          dailyNutrition['targetFat'] = dailyNutrition['targetFat'] < 0 ? 0 : dailyNutrition['targetFat'];
        });
      } else {
        print('User document does not exist for UID: ${user.uid}');
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _updateDailyNutrition(DateTime date) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        print('User not logged in.');
        if (mounted) {
          setState(() {
            todayFoods = [];
            dailyNutrition['calories'] = 0;
            dailyNutrition['protein'] = 0;
            dailyNutrition['carbs'] = 0;
            dailyNutrition['fat'] = 0;
          });
        }
        return;
      }

      DateTime startOfDay = DateTime(date.year, date.month, date.day);
      DateTime endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      QuerySnapshot foodQuery = await _firestore
          .collection('users').doc(user.uid).collection('food_history')
          .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
          .where('timestamp', isLessThanOrEqualTo: endOfDay)
          .orderBy('timestamp', descending: true)
          .get();

      int totalCalories = 0, totalProtein = 0, totalCarbs = 0, totalFat = 0;
      List<Map<String, dynamic>> foods = [];

      for (var doc in foodQuery.docs) {
        Map<String, dynamic> foodData = doc.data() as Map<String, dynamic>;
        foods.add({
          'id': doc.id,
          'name': foodData['food'] ?? 'อาหารไม่ระบุชื่อ',
          'calories': (foodData['calories'] as num?)?.toInt() ?? 0,
          'protein': (foodData['protein'] as num?)?.toInt() ?? 0,
          'carbs': (foodData['carbs'] as num?)?.toInt() ?? 0,
          'fat': (foodData['fat'] as num?)?.toInt() ?? 0,
          'timestamp': foodData['timestamp'],
        });
        totalCalories += (foodData['calories'] as num? ?? 0).toInt();
        totalProtein += (foodData['protein'] as num? ?? 0).toInt();
        totalCarbs += (foodData['carbs'] as num? ?? 0).toInt();
        totalFat += (foodData['fat'] as num? ?? 0).toInt();
      }

      if (mounted) {
        setState(() {
          todayFoods = foods;
          dailyNutrition['calories'] = totalCalories;
          dailyNutrition['protein'] = totalProtein;
          dailyNutrition['carbs'] = totalCarbs;
          dailyNutrition['fat'] = totalFat;
        });
      }
    } catch (e) {
      print('Error updating daily nutrition for date $date: $e');
      if (mounted) {
        setState(() {
          todayFoods = [];
          dailyNutrition['calories'] = 0;
          dailyNutrition['protein'] = 0;
          dailyNutrition['carbs'] = 0;
          dailyNutrition['fat'] = 0;
        });
      }
    }
  }

  // --- UI Building Functions ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 47, 130, 174),
      appBar: _buildAppBar(),
      body: isLoading ? _buildLoadingIndicator() : _buildContent(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Image.asset('assets/icon/logo.png', width: 150, height: 100),centerTitle: true,
      backgroundColor: const Color.fromARGB(255, 70, 51, 43),
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: () {
            _loadData();
          },
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE94560)),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildCalendarBox(),
          const SizedBox(height: 16),
          _buildDailyNutritionBox(),
          const SizedBox(height: 16),
          _buildCaloriesProgressBox(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildPieChartBox('โปรตีน', dailyNutrition['protein'], dailyNutrition['targetProtein'], Colors.red)),
              const SizedBox(width: 8),
              Expanded(child: _buildPieChartBox('คาร์โบไฮเดรต', dailyNutrition['carbs'], dailyNutrition['targetCarbs'], Colors.orange)),
            ],
          ),
          const SizedBox(height: 16),
          _buildPieChartBox('ไขมัน', dailyNutrition['fat'], dailyNutrition['targetFat'], Colors.yellow),
          const SizedBox(height: 16),
          _buildCardWrapper(
            title: 'รายการอาหารที่บันทึกสำหรับวันนี้',
            child: _buildFoodListInMainScreen(todayFoods),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarBox() {
    return _buildCardWrapper(
      title: 'ปฏิทินการกิน',
      child: TableCalendar<Map<String, dynamic>>(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
          _updateDailyNutrition(selectedDay);
          _showDayDetailDialog(selectedDay);
        },
        onFormatChanged: (format) => setState(() => _calendarFormat = format),
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          todayDecoration: BoxDecoration(color: const Color(0xFFE94560), shape: BoxShape.circle),
          selectedDecoration: BoxDecoration(color: const Color.fromARGB(255, 47, 130, 174), shape: BoxShape.circle),
          defaultTextStyle: const TextStyle(color: Colors.white),
          todayTextStyle: const TextStyle(color: Colors.white),
          selectedTextStyle: const TextStyle(color: Colors.white),
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: const TextStyle(color: Colors.white, fontSize: 16),
          leftChevronIcon: const Icon(Icons.chevron_left, color: Colors.white),
          rightChevronIcon: const Icon(Icons.chevron_right, color: Colors.white),
        ),
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(color: Colors.white70),
          weekendStyle: TextStyle(color: Colors.white70),
        ),
      ),
    );
  }

 Widget _buildDailyNutritionBox() {
  return _buildCardWrapper(
    title: 'พลังงานในวันนี้',
    child: Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceEvenly,
          maxY: _getMaxValue(),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => Colors.black87,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final titles = ['แคลลอรี่', 'โปรตีน', 'คาร์บ', 'ไขมัน'];
                final values = [
                  dailyNutrition['calories'],
                  dailyNutrition['protein'],
                  dailyNutrition['carbs'],
                  dailyNutrition['fat']
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
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: [
            _buildNutritionBarData(0, dailyNutrition['calories'].toDouble(), const Color(0xFF4A90E2)),
            _buildNutritionBarData(1, dailyNutrition['protein'].toDouble(), const Color(0xFF4A90E2)),
            _buildNutritionBarData(2, dailyNutrition['carbs'].toDouble(), const Color(0xFF4A90E2)),
            _buildNutritionBarData(3, dailyNutrition['fat'].toDouble(), const Color(0xFF4A90E2)),
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
        backDrawRodData: BackgroundBarChartRodData(
          show: false,
        ),
      ),
    ],
  );
}

double _getMaxValue() {
  final values = [
    dailyNutrition['calories'].toDouble(),
    dailyNutrition['protein'].toDouble(),
    dailyNutrition['carbs'].toDouble(),
    dailyNutrition['fat'].toDouble(),
  ];
  
  final maxValue = values.reduce((a, b) => a > b ? a : b);
  
  // เพิ่ม 20% ของค่าสูงสุดเพื่อให้มีพื้นที่ว่างด้านบน
  return maxValue * 1.2;
}


  Widget _buildCaloriesProgressBox() {
    double progress = (dailyNutrition['targetCalories'] > 0)
        ? dailyNutrition['calories'] / dailyNutrition['targetCalories']
        : 0.0;
    
    if (progress > 1.0) progress = 1.0;

    int remainingCalories = dailyNutrition['targetCalories'] - dailyNutrition['calories'];
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
                        colors: [Color.fromARGB(255, 38, 241, 16), Color.fromARGB(255, 8, 101, 27)],
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    '${dailyNutrition['calories']} / ${dailyNutrition['targetCalories']} kcal',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
        ],
      ),
    );
  }

  Widget _buildPieChartBox(String title, int consumed, int target, Color color) {
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
                    titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  PieChartSectionData(
                    color: Colors.grey[700],
                    value: remainingValue,
                    title: '${target - consumed}g',
                    radius: 40,
                    titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
                centerSpaceRadius: 20,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildPieChartLegend('กิน: ${consumed}g', color),
          const SizedBox(height: 4),
          _buildPieChartLegend('เหลือ: ${target - consumed}g', Colors.grey[700]!),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildPieChartLegend(String text, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }

  Widget _buildFoodListInMainScreen(List<Map<String, dynamic>> foods) {
    if (foods.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Text(
            'ยังไม่มีข้อมูลอาหารสำหรับวันนี้',
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
        DateTime timestamp;
        if (food['timestamp'] is Timestamp) {
          timestamp = (food['timestamp'] as Timestamp).toDate();
        } else {
          print('Warning: timestamp is not Timestamp type: ${food['timestamp'].runtimeType}');
          timestamp = DateTime.now();
        }

        String timeString = '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
        return Card(
          color: const Color(0xFF1A1A2E),
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            title: Text(food['name'], style: const TextStyle(color: Colors.white, fontSize: 14)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('เวลา: $timeString', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                Text('แคลลอรี่: ${food['calories']} kcal', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
            // ตรวจสอบ: พารามิเตอร์ 'trailing' ถูกกำหนดไว้ที่นี่และควรถูกต้อง
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('P:${food['protein']}g', style: TextStyle(color: Colors.red[300], fontSize: 10)),
                Text('C:${food['carbs']}g', style: TextStyle(color: Colors.orange[300], fontSize: 10)),
                Text('F:${food['fat']}g', style: TextStyle(color: Colors.yellow[300], fontSize: 10)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardWrapper({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F3460),
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 4),
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
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  void _showDayDetailDialog(DateTime selectedDay) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F3460),
        content: const Row(
          children: [
            CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE94560))),
            SizedBox(width: 20),
            Text('กำลังโหลด...', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );

    List<Map<String, dynamic>> dayFoods = await _loadFoodForDate(selectedDay);
    if (mounted) {
      Navigator.of(context).pop();
    } else {
      return;
    }

    int totalCalories = 0, totalProtein = 0, totalCarbs = 0, totalFat = 0;
    for (var food in dayFoods) {
      totalCalories += food['calories'] as int;
      totalProtein += food['protein'] as int;
      totalCarbs += food['carbs'] as int;
      totalFat += food['fat'] as int;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F3460),
        title: Text(
          'รายการอาหารวันที่ ${selectedDay.day}/${selectedDay.month}/${selectedDay.year}',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNutritionSummary(totalCalories, totalProtein, totalCarbs, totalFat),
              const SizedBox(height: 16),
              Text('รายการอาหาร (${dayFoods.length} รายการ)', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildFoodListInDialog(dayFoods),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ปิด', style: TextStyle(color: Color(0xFFE94560))),
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _loadFoodForDate(DateTime selectedDate) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return [];

      DateTime startOfDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
      DateTime endOfDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 23, 59, 59);

      QuerySnapshot foodQuery = await _firestore
          .collection('users').doc(user.uid).collection('food_history')
          .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
          .where('timestamp', isLessThanOrEqualTo: endOfDay)
          .orderBy('timestamp', descending: true)
          .get();

      return foodQuery.docs.map((doc) {
        Map<String, dynamic> foodData = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'name': foodData['food'] ?? 'อาหารไม่ระบุชื่อ',
          'calories': (foodData['calories'] as num?)?.toInt() ?? 0,
          'protein': (foodData['protein'] as num?)?.toInt() ?? 0,
          'carbs': (foodData['carbs'] as num?)?.toInt() ?? 0,
          'fat': (foodData['fat'] as num?)?.toInt() ?? 0,
          'timestamp': foodData['timestamp'],
        };
      }).toList();
    } catch (e) {
      print('Error loading food for date: $e');
      return [];
    }
  }

  Widget _buildNutritionSummary(int calories, int protein, int carbs, int fat) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('สรุปสารอาหาร', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('แคลลอรี่รวม: $calories kcal', style: const TextStyle(color: Colors.white70)),
          Text('โปรตีน: ${protein}g', style: TextStyle(color: Colors.red[300])),
          Text('คาร์โบไฮเดรต: ${carbs}g', style: TextStyle(color: Colors.orange[300])),
          Text('ไขมัน: ${fat}g', style: TextStyle(color: Colors.yellow[300])),
        ],
      ),
    );
  }

  Widget _buildFoodListInDialog(List<Map<String, dynamic>> dayFoods) {
    if (dayFoods.isEmpty) {
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
        itemCount: dayFoods.length,
        itemBuilder: (context, index) {
          var food = dayFoods[index];
          DateTime timestamp;
          if (food['timestamp'] is Timestamp) {
            timestamp = (food['timestamp'] as Timestamp).toDate();
          } else {
            print('Warning: timestamp is not Timestamp type: ${food['timestamp'].runtimeType}');
            timestamp = DateTime.now();
          }

          String timeString = '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
          return Card(
            color: const Color(0xFF1A1A2E),
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              title: Text(food['name'], style: const TextStyle(color: Colors.white, fontSize: 14)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('เวลา: $timeString', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                  Text('แคลลอรี่: ${food['calories']} kcal', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
              // ตรวจสอบ: พารามิเตอร์ 'trailing' ถูกกำหนดไว้ที่นี่และควรถูกต้อง
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('P:${food['protein']}g', style: TextStyle(color: Colors.red[300], fontSize: 10)),
                  Text('C:${food['carbs']}g', style: TextStyle(color: Colors.orange[300], fontSize: 10)),
                  Text('F:${food['fat']}g', style: TextStyle(color: Colors.yellow[300], fontSize: 10)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}