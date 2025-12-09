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
    
    // 👇 FIX #1: APK Splitting ko disable aur simplify kiya gaya hai
    splits {
        abi {
            isEnable = true
            reset()
            isUniversalApk = true // Single universal APK guaranteed
        }
        density {
            isEnable = false // Density splitting ko disable kiya gaya hai
        }
    }

    // 👇 FIX #2: Output file ka naam 'app-release.apk' par fix kiya gaya hai
    applicationVariants.all {
        it.outputs.all { output ->
            if (it.buildType.name == "release") {
                output.outputFileName.set("app-release.apk")
            }
        }
    }

    buildTypes {
        release {
            // 🔥 Mapbox + Release APK fix
            isMinifyEnabled = false     // Disable code shrinking for now
            isShrinkResources = false   // Disable resource shrinking
            signingConfig = signingConfigs.getByName("debug")
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
