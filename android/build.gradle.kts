// Top-level build file where you can add configuration options common to all sub-projects/modules.

buildscript {
    // 🌟 Kotlin Syntax Fix: ext.kotlin_version ko yahan define nahi karte
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // 🌟 Kotlin Syntax Fix: classpath ki jagah 'classpath' use hota hai
        // Kotlin Version tumhara 'settings.gradle.kts' ya 'gradle-wrapper.properties' se aana chahiye
        // Ya fir yahan double quotes mein define karo
        val kotlinVersion = "1.8.20" 
        
        // Tumhari dependencies:
        classpath("com.android.tools.build:gradle:8.0.0") 
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
        // Agar koi aur classpath ho toh yahan add karo
    }
}

// Tumhari build directory configuration:
val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// 🌟 CRITICAL FIX: MAPBOX REPOSITORY (Kotlin Syntax)
allprojects {
    repositories {
        google()
        mavenCentral()
        
        // MapBox Maven repository config
        maven {
            url = uri("https://api.mapbox.com/downloads/v2/releases/maven")
            credentials {
                username = "mapbox" 
                // Kotlin Syntax mein token access
                password = project.properties["MAPBOX_DOWNLOADS_TOKEN"] as String? ?: "" 
            }
            authentication {
                basic(credentials)
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
