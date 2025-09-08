import 'package:flutter_riverpod/flutter_riverpod.dart';

// Navigation State Provider
final navigationIndexProvider = StateProvider<int>((ref) => 0);

// Week Days Provider
final weekDaysProvider = Provider<List<DateTime>>((ref) {
  DateTime today = DateTime.now();
  DateTime firstDay = today.subtract(Duration(days: today.weekday - 1));
  return List.generate(7, (i) => firstDay.add(Duration(days: i)));
});

// Current Date Provider
final currentDateProvider = Provider<DateTime>((ref) => DateTime.now());
