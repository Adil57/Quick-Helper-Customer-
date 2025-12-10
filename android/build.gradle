import java.io.FileInputStream
import java.util.Properties

// 🟢 FIX 1: local.properties file ko load kiya gaya
def localPropertiesFile = new File(rootProject.projectDir, "android/local.properties")
def localProperties = new Properties()

if (localPropertiesFile.exists()) {
    localProperties.load(new FileInputStream(localPropertiesFile))
}

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath 'com.android.tools.build:gradle:8.1.4'  // Stable AGP 8.1.4 (beta 8.11.1 avoid kar)
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.10"  // Stable Kotlin 1.9.10
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()

        // ============================================
        // ⭐ MAPBOX MAVEN + UNIVERSAL TOKEN FALLBACK
        // ============================================
        maven {
            url "https://api.mapbox.com/downloads/v2/releases/maven"
            authentication {
                basic(BasicAuthentication)
            }
            credentials {
                username = "mapbox"
                // 🟢 FIX 2: Sabse pehle manually loaded localProperties se token uthaya
                password = localProperties.getProperty("MAPBOX_DOWNLOADS_TOKEN")
                        ?: System.getenv("MAPBOX_DOWNLOADS_TOKEN")
                        ?: ""
            }
        }
    }
}

// 🟢 MAIN FIX: Subprojects namespace workaround for AGP 8.0+ (path mismatch aur APK find error fix)
subprojects {
    afterEvaluate { project ->
        if (project.hasProperty('android')) {
            project.android {
                if (namespace == null) {
                    namespace project.group ?: "com.example.${project.name}"
                }
            }
        }
    }
}

tasks.register('clean', Delete) {
    delete rootProject.layout.buildDirectory
}
