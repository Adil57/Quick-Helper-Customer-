import java.util.Properties

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.adil.quickhelper"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.adil.quickhelper"
        minSdk = 23
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"

        // ================================
        // ⭐ MAPBOX TOKEN FIX (FINAL)
        // ================================
        val mapboxToken =
            System.getenv("MAPBOX_DOWNLOADS_TOKEN")
                ?: project.findProperty("MAPBOX_DOWNLOADS_TOKEN")?.toString()
                ?: ""

        manifestPlaceholders["MAPBOX_DOWNLOADS_TOKEN"] = mapboxToken
        println("📦 Mapbox Token Applied in manifestPlaceholders: $mapboxToken")
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        debug {
            isMinifyEnabled = false
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib:1.9.22")

    // ⭐ Ensure Mapbox dependencies resolve
    implementation("com.mapbox.maps:android:11.4.0")
}
