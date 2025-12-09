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

    // 👇 APK Splitting Fix (Taki file ka naam simple rahe)
    splits {
        abi {
            isEnable = true
            reset()
            isUniversalApk = true 
        }
        density {
            isEnable = false 
        }
    }
    
    // 👇 FINAL FIX: Release signing issue solve karne ke liye
    buildTypes {
        release {
            isMinifyEnabled = false     
            isShrinkResources = false   
            // 🔥 Yahan se 'signingConfig = signingConfigs.getByName("debug")' hata diya gaya hai.
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

// 👇 APK Naming Guarantee (Compilation Error Fix ke baad yeh kaam karna chahiye)
androidComponents {
    onVariants(selector().withBuildType("release")) { variant ->
        variant.outputs.all { output ->
            output.outputFileName.set("app-release.apk")
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
