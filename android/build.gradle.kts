// Top-level build file where you can add configuration options common to all sub-projects/modules.

// Import line hata diya gaya hai, kyunki woh unnecessary errors de raha tha.

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        val kotlinVersion = "1.8.20" 
        
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

// 🌟 FINAL CRITICAL FIX: MAPBOX REPOSITORY
// Yeh syntax 'basic()' function ko directly access karne ke bajaye, 
// 'authentication.create' method ko BasicAuthentication type ke saath use karta hai.
allprojects {
    repositories {
        google()
        mavenCentral()
        
        maven {
            url = uri("https://api.mapbox.com/downloads/v2/releases/maven")
            
            // 🔥 YEH HAI FINAL FIX: Using Groovy-style configuration with the correct type.
            // Hum Gradle ko bata rahe hain ki "basic" naam ki authentication BasicAuthentication type ki hai.
            authentication { 
                basic(DelegateClosure.of<org.gradle.api.authentication.BasicAuthentication> {}) 
            }
            
            credentials {
                username = "mapbox" 
                password = project.properties["MAPBOX_DOWNLOADS_TOKEN"] as String? ?: "" 
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
