// Top-level build file where you can add configuration options common to all sub-projects/modules.

// Import sirf dsl ke liye rakha hai
import org.gradle.kotlin.dsl.* buildscript {
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
allprojects {
    repositories {
        google()
        mavenCentral()
        
        maven {
            url = uri("https://api.mapbox.com/downloads/v2/releases/maven")
            
            // ✅ FIX: FINAL SAFE SYNTAX - Casting to AuthenticationSupported to resolve 'authentication' property
            (this as org.gradle.api.artifacts.repositories.AuthenticationSupported).authentication.register("basic", org.gradle.api.authentication.BasicAuthentication::class.java)
            
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
