// Top-level build file where you can add configuration options common to all sub-projects/modules.

// Tumhari purani buildscript configuration:
buildscript {
    ext.kotlin_version = '1.8.20' // Ya tumhara latest version
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Buildscript dependencies yahan aayengi
        classpath 'com.android.tools.build:gradle:8.0.0' // Ya tumhara latest version
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
        // Flutter plugin ki dependency bhi yahan hogi
    }
}

// -----------------------------------------------------------------------------
// TUMHARI BUILD DIRECTORY CONFIGURATION (MapBox fix ke saath)
// -----------------------------------------------------------------------------

// Tumhari build directory definition:
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

// -----------------------------------------------------------------------------
// 🌟 CRITICAL FIX: MAPBOX REPOSITORY
// -----------------------------------------------------------------------------

allprojects {
    repositories {
        google()
        mavenCentral()
        
        // 🚨 CRITICAL FIX: MAPBOX SDK REGISTRY CONFIGURATION
        // Yeh block SDK download karne ki permission dega (Token use karke)
        maven {
            url 'https://api.mapbox.com/downloads/v2/releases/maven'
            authentication {
                basic(credentials)
            }
            credentials {
                // Gradle yahan se environment variable uthayega (jo local.properties mein inject hua hai)
                username = 'mapbox' 
                password = project.properties['MAPBOX_DOWNLOADS_TOKEN'] ?: "" 
            }
        }
    }
}

// -----------------------------------------------------------------------------

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
