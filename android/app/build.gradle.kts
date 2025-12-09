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

    // 👇 FIX #1: APK Splitting ko disable aur simplify kiya gaya hai (This is stable)
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
    
    // ❌ UNSTABLE NAMING LOGIC POORA HATA DIYA GAYA HAI TAKI COMPILATION ERROR NA AAYE.
    
    buildTypes {
        release {
            isMinifyEnabled = false     
            isShrinkResources = false   
            // signingConfig = signingConfigs.getByName("debug") line removed 
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
