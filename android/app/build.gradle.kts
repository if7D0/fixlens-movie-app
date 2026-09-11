import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Upload-key credentials (gitignored). Absent = debug-signed release
// (fine for GitHub APK sharing, NOT for Play Store).
val keystoreProperties = Properties().apply {
    rootProject.file("key.properties").takeIf { it.exists() }?.inputStream()?.use(::load)
}

val hasUploadKey =
    keystoreProperties.getProperty("storeFile")?.isNotBlank() == true

android {
    namespace = "com.fixlens.fixlens_movie_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    signingConfigs {
        create("upload") {
            keyAlias = keystoreProperties.getProperty("keyAlias", "")
            keyPassword = keystoreProperties.getProperty("keyPassword", "")
            storePassword = keystoreProperties.getProperty("storePassword", "")
            // Set only when present: file("") throws at configuration time.
            keystoreProperties.getProperty("storeFile", "")
                .takeIf { it.isNotBlank() }
                ?.let { storeFile = file(it) }
        }
    }

    defaultConfig {
        applicationId = "com.fixlens.fixlens_movie_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName(
                if (hasUploadKey) "upload" else "debug",
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
