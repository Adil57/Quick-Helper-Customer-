import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.quick_helper_customer"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    // === Naya Signing Config Code Yahan Shuru (Zaroori) ===
    signingConfigs {
        create("release") {
            val keyPropertiesFile = rootProject.file("key.properties")
            if (keyPropertiesFile.exists()) {
                val keyProperties = Properties().apply { load(FileInputStream(keyPropertiesFile)) }
                storeFile = file(keyProperties["storeFile"] as String)
                storePassword = keyProperties["storePassword"] as String
                keyAlias = keyProperties["keyAlias"] as String
                keyPassword = keyProperties["keyPassword"] as String
            }
        }
    }
    // === Naya Signing Config Code Yahan Khatam ===

    defaultConfig {
        applicationId = "com.example.quick_helper_customer"
        minSdk = 21
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        manifestPlaceholders["auth0Domain"] = "adil888.us.auth0.com"
        manifestPlaceholders["auth0Scheme"] = "com.quickhelper.app"

        resValue(
            "string",
            "mapbox_access_token",
            project.properties["MAPBOX_ACCESS_TOKEN"] as String? ?: ""
        )
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            // === Signing Config Ko Apply Karein ===
            signingConfig = signingConfigs.getByName("release")
            // =====================================
        }
    }
    
    // APK copy logic is removed.
}

flutter {
    source = "../.."
}

repositories {
    google()
    mavenCentral()
}

dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib")
}
