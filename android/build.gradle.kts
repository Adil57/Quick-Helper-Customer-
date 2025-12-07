// Top-level build file where you can add configuration options common to all sub-projects/modules.

// 🔥 CRITICAL FIX: Missing imports for delegate closure and authentication types in older KTS
import org.gradle.kotlin.dsl.* import org.gradle.api.internal.artifacts.repositories.AuthenticationSupported
import org.gradle.api.artifacts.repositories.MavenArtifactRepository
import org.gradle.api.internal.artifacts.repositories.AuthenticationSupportedInternal // Just in case
import org.gradle.internal.impldep.org.codehaus.groovy.runtime.DelegatingScript.DelegateClosure // Isse DelegateClosure resolve hoga


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
allprojects {
    repositories {
        google()
        mavenCentral()
        
        maven {
            url = uri("https://api.mapbox.com/downloads/v2/releases/maven")
            
            // ✅ FIX: authentication.create<> method jo BasicAuthentication ko manually set karta hai
            // Yeh 'basic()' aur 'DelegateClosure' errors ko bypass karega.
            (this as AuthenticationSupported).authentication.create<org.gradle.api.authentication.BasicAuthentication>("basic")
            
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
