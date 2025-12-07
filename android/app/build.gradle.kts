plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.quick_helper_customer"
    // Compile SDK 36 set hai, jo theek hai.
    compileSdk = 36 
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.quick_helper_customer"
        
        minSdk = 21 
        
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Auth0 ke manifest placeholders theek hain
        manifestPlaceholders["auth0Domain"] = "adil888.us.auth0.com" 
        manifestPlaceholders["auth0Scheme"] = "com.quickhelper.app" 
        
        // 🌟 CRITICAL FIX: MapBox Public Token ko GitHub Actions environment se uthana.
        // Ye token app ko map load karne ke liye chahiye.
        resValue("string", "mapbox_access_token", project.properties["MAPBOX_ACCESS_TOKEN"] as String? ?: "")
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
