// Top-level build file where you can add configuration options common to all sub-projects/modules.

// ❌ OLD: import org.gradle.internal.authentication.BasicAuthentication // HATA DIYA!

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

// 🌟 CRITICAL FIX: MAPBOX REPOSITORY (Corrected KTS Syntax)
allprojects {
    repositories {
        google()
        mavenCentral()
        
        maven {
            url = uri("https://api.mapbox.com/downloads/v2/releases/maven")
            
            // ✅ FIX: 'basic()' function ko authentication block ke andar wrap karo
            authentication {
                basic() 
            }
            
            credentials {
                username = "mapbox" 
                // Yeh token local.properties/env se uthaya jayega
                password = project.properties["MAPBOX_DOWNLOADS_TOKEN"] as String? ?: "" 
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
