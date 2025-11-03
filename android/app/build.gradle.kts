import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") // Firebase
}

// Load keystore properties safely
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
} else {
    throw GradleException("key.properties file not found at: $keystorePropertiesFile")
}

android {
    namespace = "com.digvijay.instprint"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    defaultConfig {
        applicationId = "com.digvijay.instprint"
        minSdk = flutter.minSdkVersion // Ensure minSdk matches Flutter plugins
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias")
                ?: throw GradleException("keyAlias not found in key.properties")
            keyPassword = keystoreProperties.getProperty("keyPassword")
                ?: throw GradleException("keyPassword not found in key.properties")
            storeFile = keystoreProperties.getProperty("storeFile")?.let { file(it) }
                ?: throw GradleException("storeFile not found in key.properties")
            storePassword = keystoreProperties.getProperty("storePassword")
                ?: throw GradleException("storePassword not found in key.properties")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
        debug {
            // Optional: debug signing
            signingConfig = signingConfigs.getByName("release")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    buildFeatures {
        viewBinding = true
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("com.google.firebase:firebase-analytics:21.3.0")
    implementation("com.google.firebase:firebase-auth:22.2.0")
    implementation("com.google.firebase:firebase-firestore:24.7.1") // ✅ fixed
    implementation("com.google.firebase:firebase-storage:21.1.0")
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.appcompat:appcompat:1.7.0")
}
