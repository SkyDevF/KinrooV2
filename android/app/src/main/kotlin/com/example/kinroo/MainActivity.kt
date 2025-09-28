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
