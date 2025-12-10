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
        }
    }
    
    // === FINAL CORRECTED CODE (APK copy fix) ===
    applicationVariants.configureEach { variant ->
        if (variant.buildType.name == "release" || variant.buildType.name == "debug") {
            // Hum assemble.doLast ki jagah Task API use karenge, jo Kotlin DSL mein correct hai
            tasks.named("assemble${variant.name.capitalize()}").configure {
                doLast {
                    copy {
                        from("../../../build/app/outputs/apk/${variant.buildType.name}/app-${variant.buildType.name}.apk")
                        into("../../../build/host/outputs/apk/")
                    }
                }
            }
        }
    }
    // === FINAL CORRECTED CODE YAHAN KHATAM ===
}

flutter {
    source = "../.."
}

repositories {
    google()
    mavenCentral()
}

// ❗ FIX: REMOVE kotlin_version property (this was breaking your build)
dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib")
}
