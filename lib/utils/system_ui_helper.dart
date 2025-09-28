import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SystemUIHelper {
  /// ตั้งค่า system UI สำหรับ Edge-to-Edge display
  static void setupEdgeToEdge() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
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

  /// ตั้งค่า system UI overlay style สำหรับ dark theme
  static void setDarkSystemUIOverlay() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );
  }

  /// ตั้งค่า system UI สำหรับหน้าจอเฉพาะ
  static void setSystemUIForScreen({
    required bool isDarkMode,
    Color? statusBarColor,
    Color? navigationBarColor,
  }) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: statusBarColor ?? Colors.transparent,
        statusBarIconBrightness: isDarkMode
            ? Brightness.light
            : Brightness.dark,
        statusBarBrightness: isDarkMode ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: navigationBarColor ?? Colors.transparent,
        systemNavigationBarIconBrightness: isDarkMode
            ? Brightness.light
            : Brightness.dark,
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
