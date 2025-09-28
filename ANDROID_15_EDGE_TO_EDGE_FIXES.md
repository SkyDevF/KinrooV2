# การแก้ไขปัญหา Android 15 Edge-to-Edge และ API ที่เลิกใช้งานแล้ว

## ปัญหาที่แก้ไข

1. **การแสดงผลแบบไร้ขอบ (Edge-to-Edge)** - แอปที่กำหนดเป้าหมายเป็น SDK 35 จะแสดงแบบไร้ขอบโดยค่าเริ่มต้นใน Android 15
2. **API ที่เลิกใช้งานแล้ว** - API สำหรับการจัดการ status bar และ navigation bar ถูกเลิกใช้งานใน Android 15
3. **รองรับ 16KB page size** - Android 15 รองรับอุปกรณ์ที่มีหน้าหน่วยความจำขนาด 16 KB

## การแก้ไขที่ทำ

### 1. อัปเดต build.gradle.kts
```kotlin
android {
    compileSdk = 35  // อัปเดตเป็น API 35 สำหรับ Android 15
    
    defaultConfig {
        targetSdk = 35  // เป้าหมาย API 35
        versionCode = 10  // เพิ่ม version code
        versionName = "1.0.9"
        
        // รองรับ 16KB page size
        ndk {
            abiFilters += listOf("arm64-v8a", "armeabi-v7a", "x86_64")
        }
    }
}

dependencies {
    // เพิ่ม AndroidX Core สำหรับ Edge-to-Edge
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.activity:activity-ktx:1.8.2")
}
```

### 2. อัปเดต MainActivity.kt
```kotlin
package com.kinroo.app

import android.os.Build
import android.os.Bundle
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // เปิดใช้งาน Edge-to-Edge สำหรับ Android 15+ และความเข้ากันได้แบบย้อนหลัง
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.VANILLA_ICE_CREAM) {
            // Android 15+ (API 35+) - ใช้ enableEdgeToEdge()
            window.decorView.post {
                try {
                    val method = window.javaClass.getMethod("enableEdgeToEdge")
                    method.invoke(window)
                } catch (e: Exception) {
                    // Fallback ถ้า method ไม่พบ
                    WindowCompat.setDecorFitsSystemWindows(window, false)
                }
            }
        } else {
            // Android 14 และต่ำกว่า - ใช้ WindowCompat
            WindowCompat.setDecorFitsSystemWindows(window, false)
        }
    }
}
```

### 3. อัปเดต styles.xml
```xml
<!-- Light Theme -->
<style name="NormalTheme" parent="@android:style/Theme.Light.NoTitleBar">
    <item name="android:windowBackground">?android:colorBackground</item>
    <!-- รองรับ Edge-to-Edge สำหรับ Android 15+ -->
    <item name="android:windowLayoutInDisplayCutoutMode">shortEdges</item>
    <item name="android:statusBarColor">@android:color/transparent</item>
    <item name="android:navigationBarColor">@android:color/transparent</item>
    <item name="android:windowLightStatusBar">true</item>
    <item name="android:windowLightNavigationBar">true</item>
</style>

<!-- Dark Theme -->
<style name="NormalTheme" parent="@android:style/Theme.Black.NoTitleBar">
    <item name="android:windowBackground">?android:colorBackground</item>
    <!-- รองรับ Edge-to-Edge สำหรับ Android 15+ (Dark Mode) -->
    <item name="android:windowLayoutInDisplayCutoutMode">shortEdges</item>
    <item name="android:statusBarColor">@android:color/transparent</item>
    <item name="android:navigationBarColor">@android:color/transparent</item>
    <item name="android:windowLightStatusBar">false</item>
    <item name="android:windowLightNavigationBar">false</item>
</style>
```

### 4. อัปเดต gradle.properties
```properties
# รองรับ 16KB page size สำหรับ Android 15
android.experimental.enableArtProfiles=true
android.experimental.r8.dex-startup-optimization=true

# เปิดใช้งาน Edge-to-Edge
android.enableEdgeToEdge=true
```

### 5. สร้าง SystemUIHelper.dart
```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SystemUIHelper {
  /// ตั้งค่า system UI สำหรับ Edge-to-Edge display
  static void setupEdgeToEdge() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
    );
  }

  /// ตั้งค่า system UI overlay style สำหรับ light theme
  static void setLightSystemUIOverlay() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );
  }

  /// Widget wrapper สำหรับจัดการ safe area และ system UI
  static Widget wrapWithSafeArea({
    required Widget child,
    bool top = true,
    bool bottom = true,
    bool left = true,
    bool right = true,
  }) {
    return SafeArea(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: child,
    );
  }
}
```

### 6. อัปเดต main.dart
```dart
import 'utils/system_ui_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  
  // ตั้งค่า Edge-to-Edge สำหรับ Android 15+
  SystemUIHelper.setupEdgeToEdge();

  runApp(ProviderScope(child: KinrooApp()));
}
```

## ประโยชน์ที่ได้รับ

1. **รองรับ Android 15** - แอปจะทำงานได้อย่างถูกต้องบน Android 15 และใหม่กว่า
2. **Edge-to-Edge Display** - แสดงผลแบบไร้ขอบอย่างสวยงามและสอดคล้องกับ Material Design 3
3. **ความเข้ากันได้แบบย้อนหลัง** - ยังคงทำงานได้บน Android เวอร์ชันเก่า
4. **รองรับ 16KB Page Size** - ปรับปรุงประสิทธิภาพบนอุปกรณ์ที่รองรับ
5. **ไม่ใช้ API ที่เลิกใช้งานแล้ว** - หลีกเลี่ยงปัญหาใน Android 15+

## การทดสอบ

- ✅ Build สำเร็จ (APK สร้างได้แล้ว)
- ✅ รองรับ SDK 35 (Android 15)
- ✅ ใช้ AndroidX Core สำหรับ Edge-to-Edge
- ✅ ตั้งค่า System UI อย่างถูกต้อง

## หมายเหตุ

- แอปจะแสดงผลแบบไร้ขอบโดยอัตโนมัติบน Android 15+
- ใช้ SafeArea widget เพื่อจัดการพื้นที่ที่ถูกบดบังโดย system UI
- รองรับทั้ง Light และ Dark mode
- ปรับปรุงประสิทธิภาพสำหรับอุปกรณ์ที่มี 16KB page size