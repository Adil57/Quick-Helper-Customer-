plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.quick_helper_customer"
    // Compile SDK ko 34 set kar dete hain, jo latest stable version hai.
    compileSdk = 36 
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    // JVM Target ko Java 17 ke liye fix kiya.
    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.quick_helper_customer"
        
        // 🔴 CRITICAL FIX: minSdk ko 21 set kiya.
        // Yehi reason tha Step 5 ke failure ka.
        minSdk = 21 
        
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Auth0 ke manifest placeholders theek hain
        manifestPlaceholders["auth0Domain"] = "adil888.us.auth0.com" 
        manifestPlaceholders["auth0Scheme"] = "com.quickhelper.app" 
    }

    buildTypes {
        release {
            // Signing with the debug keys for now.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
