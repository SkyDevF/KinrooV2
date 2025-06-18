plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.kinroo"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.kinroo"
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // บังคับให้ใช้ TensorFlow Lite runtime เวอร์ชัน 2.12.0 (หรือเวอร์ชันล่าสุดที่รองรับ FULLY_CONNECTED version 12)
    implementation("org.tensorflow:tensorflow-lite:2.12.0")
    // รวม Flex Ops (Select TF Ops) เวอร์ชัน 2.12.0 ซึ่งช่วยให้ interpreter รองรับ op ที่ใหม่ขึ้น
    implementation("org.tensorflow:tensorflow-lite-select-tf-ops:2.12.0")
    // (ถ้าต้องการลอง GPU delegate เพิ่มได้ แต่ในที่นี้เราพยายามแก้ให้ใช้ CPU)
    // implementation("org.tensorflow:tensorflow-lite-gpu:2.12.0")
    // Dependency อื่นๆ หากมี
}

flutter {
    source = "../.."
}