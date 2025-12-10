// =============================
// Flutter / Kotlin / AGP Setup
// =============================
pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.1.4" apply false  // Stable AGP 8.1.4
    id("org.jetbrains.kotlin.android") version "1.9.10" apply false  // Stable Kotlin 1.9.10
}

// ====================================
// 🔥 MAPBOX TOKEN LOADING — FINAL FIX
// ====================================
val mapboxToken: String? =
    System.getenv("MAPBOX_DOWNLOADS_TOKEN")
        ?: gradle.startParameter.projectProperties["MAPBOX_DOWNLOADS_TOKEN"]?.toString()

if (mapboxToken != null) {
    println("✅ Mapbox token loaded")
} else {
    println("⚠ WARNING: MAPBOX_DOWNLOADS_TOKEN missing")
}

// =============================
// Include Main App Module
// =============================
include(":app")

// =============================
// (OPTIONAL) Extra Repository
// Needed by some plugins
// =============================
dependencyResolutionManagement {
    repositories {
        google()
        mavenCentral()

        // Mapbox Maven Repo
        maven {
            url = uri("https://api.mapbox.com/downloads/v2/releases/maven")
            credentials {
                username = "mapbox"
                password = mapboxToken
            }
            authentication {
                create<BasicAuthentication>("basic")
            }
        }
    }
}
