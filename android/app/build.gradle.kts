import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    // REMOVED: id("kotlin-android") - migrating to built-in Kotlin
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()

if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.skynestinnovations.everywhere.everywhere"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "29.0.13113456"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    // REMOVED: kotlinOptions block - this is now handled by the kotlin block below

    defaultConfig {
        applicationId = "com.amril.app"
        minSdk = flutter.minSdkVersion
        // Pinned to 34 deliberately, and it MUST stay <=34 for the keyboard fix
        // in MainActivity to work. The Flutter engine calls enableEdgeToEdge()
        // itself (edge-to-edge default), which disables adjustResize and stops
        // TextFields rising above the keyboard app-wide. MainActivity re-asserts
        // WindowCompat.setDecorFitsSystemWindows(true) to undo that — but on
        // API 35+ the OS FORCE-enables edge-to-edge and ignores that call, so we
        // stay on 34 until every input screen is migrated to manual inset
        // handling for true edge-to-edge.
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

// ADD THIS: Built-in Kotlin configuration (replaces kotlin-android plugin)
kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11
    }
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:34.14.0"))
    implementation("com.google.firebase:firebase-analytics")
}