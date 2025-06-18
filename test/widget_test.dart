import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinroo/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // ✅ เปลี่ยน `MyApp()` เป็น `KinrooApp()` ตามที่กำหนดใน main.dart
    await tester.pumpWidget(KinrooApp());

    // ตรวจสอบว่า Counter เริ่มต้นที่ 0
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // กดปุ่ม "+" เพื่อเพิ่มค่า
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // ตรวจสอบว่าค่าถูกเพิ่มเป็น 1
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}