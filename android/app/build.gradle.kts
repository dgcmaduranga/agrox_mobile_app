plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")

    // 🔥 ADD THIS
    id("com.google.gms.google-services")
}

android {
    namespace = "com.agrox.mobile" // 🔥 CHANGE
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17

        // ✅ REQUIRED for flutter_local_notifications
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.agrox.mobile" // 🔥 CHANGE

        minSdk = flutter.minSdkVersion // 🔥 IMPORTANT for Firebase

        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // ✅ REQUIRED for flutter_local_notifications desugaring
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}