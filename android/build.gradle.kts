import java.io.FileInputStream
import java.util.Properties

// Load local.properties
val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.inputStream().use { localProperties.load(it) }
}

buildscript {
    repositories {
        google()
        mavenCentral()

        // Mapbox Maven repo
        maven("https://api.mapbox.com/downloads/v2/releases/maven") {
            authentication {
                create<BasicAuthentication>("basic")
            }
            credentials {
                username = "mapbox"
                password = System.getenv("MAPBOX_DOWNLOADS_TOKEN")
                    ?: localProperties.getProperty("MAPBOX_DOWNLOADS_TOKEN")
                    ?: ""
            }
        }
    }

    dependencies {
        classpath("com.android.tools.build:gradle:8.1.4")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.22")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()

        // Mapbox repo
        maven("https://api.mapbox.com/downloads/v2/releases/maven") {
            authentication {
                create<BasicAuthentication>("basic")
            }
            credentials {
                username = "mapbox"
                password = System.getenv("MAPBOX_DOWNLOADS_TOKEN")
                    ?: localProperties.getProperty("MAPBOX_DOWNLOADS_TOKEN")
                    ?: ""
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
