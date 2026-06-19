plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.kidcare_app"
    compileSdk = 36
    ndkVersion = "28.2.13676358"

    compileOptions {
        // 🌟 الخطوة 1: تفعيل ميزة فك التضارب للمكتبات الأساسية لحل مشكلة الإشعارات
        isCoreLibraryDesugaringEnabled = true

        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.kidcare_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 24 // تحديد الحد الأدنى الصريح ليتوافق مع مكتبة الإشعارات الحديثة
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

// 🌟 الخطوة 2: إضافة قسم الـ dependencies المفقود في أسفل الملف وحقن حزمة جوجل لحل المشكلة
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.3")
}