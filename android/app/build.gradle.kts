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

    defaultConfig {
        applicationId = "com.example.quick_helper_customer"
        minSdk = 21
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        manifestPlaceholders["auth0Domain"] = "adil888.us.auth0.com"
        manifestPlaceholders["auth0Scheme"] = "com.quickhelper.app"

        // PUBLIC Mapbox token (map rendering)
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
        }
    }
}

flutter {
    source = "../.."
}

// Repositories for Mapbox plugin
repositories {
    google()
    mavenCentral()

    maven("https://api.mapbox.com/downloads/v2/releases/maven") {
        authentication {
            create<BasicAuthentication>("basic")
        }
        credentials {
            username = "mapbox"
            password = System.getenv("MAPBOX_DOWNLOADS_TOKEN")
                ?: project.findProperty("MAPBOX_DOWNLOADS_TOKEN")?.toString()
        }
    }
}

// 🟢 MAIN FIX: Copy APK to Flutter expected path after assembleRelease (AGP 8.0+ path mismatch fix)
tasks.register<Copy>("copyFlutterApkRelease") {
    dependsOn("assembleRelease")
    from("$buildDir/outputs/apk/release/app-release.apk")
    into("../../build/app/outputs/flutter-apk")
    rename { "app-release.apk" }
    doLast {
        println("✅ APK copied to Flutter expected path: build/app/outputs/flutter-apk/app-release.apk")
    }
}

// Link the copy task to Flutter build
tasks.named("assembleRelease") {
    finalizedBy("copyFlutterApkRelease")
}
