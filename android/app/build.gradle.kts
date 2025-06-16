plugins {
    id("com.android.application")
    id("com.google.gms.google-services") // Firebase config
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin") // Must come last
}

android {
    namespace = "com.example.spotify_clone"
    compileSdk = 35
    ndkVersion = "27.0.12077973" // Required NDK version for multiple plugins

    defaultConfig {
        applicationId = "com.example.spotify_clone"
        minSdk = 23 // Required by firebase_auth and other modern plugins
        targetSdk = 35
        versionCode = 1
        versionName = "1.0"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug") // Use real signingConfig for production
        }
    }
}

flutter {
    source = "../.."
}
