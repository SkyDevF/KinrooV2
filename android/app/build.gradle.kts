import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("com.google.gms.google-services") // FlutterFire
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// ✅ โหลด key.properties
val keystoreProperties = Properties().apply {
    val keystorePropertiesFile = rootProject.file("key.properties")
    if (keystorePropertiesFile.exists()) {
        load(FileInputStream(keystorePropertiesFile))
    }
}

android {
    namespace = "com.kinroo.app"
    compileSdk = 35  // อัปเดตเป็น API 35 สำหรับ Android 15
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.kinroo.app"
        minSdk = 23
        targetSdk = 35  // เป้าหมาย API 35 สำหรับ Android 15
        versionCode = 10  // เพิ่ม version code
        versionName = "1.0.9"
        
        // รองรับ 16KB page size สำหรับ Android 15
        ndk {
            abiFilters += listOf("arm64-v8a", "armeabi-v7a", "x86_64")
        }
    }

    signingConfigs {
        create("release") {
            storeFile = file(keystoreProperties["storeFile"] ?: "key.jks")
            storePassword = keystoreProperties["storePassword"] as String
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
        }
    }

    buildTypes {
        getByName("release") {
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig = signingConfigs.getByName("release") // ✅ ใช้ signing จริง
        }
    }
}

dependencies {
    implementation("org.tensorflow:tensorflow-lite:2.12.0")
    implementation("org.tensorflow:tensorflow-lite-select-tf-ops:2.12.0")
    // implementation("org.tensorflow:tensorflow-lite-gpu:2.12.0") // ถ้าต้องการ
    
    // AndroidX Core สำหรับ Edge-to-Edge และ Android 15 compatibility
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.activity:activity-ktx:1.8.2")
}

flutter {
    source = "../.."
}