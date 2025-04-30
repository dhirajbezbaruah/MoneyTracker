import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") // Added Google Services plugin
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
keystoreProperties.load(FileInputStream(keystorePropertiesFile))

android {
    namespace = "com.fincalculators.moneytrack"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11 // Update to Java 11
        targetCompatibility = JavaVersion.VERSION_11 // Update to Java 11
        isCoreLibraryDesugaringEnabled = true // Enable desugaring
    }

    kotlinOptions {
        jvmTarget = "11" // Update to Java 11
    }

    lintOptions {
        disable("ObsoleteLintCustomCheck") // Suppress warnings about obsolete options
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    defaultConfig {
        applicationId = "com.fincalculators.moneytrack"
        minSdk = 21 // Set minimum SDK version to 21 for open_file_plus
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // Add this line for AdMob
        manifestPlaceholders["AdMobAppId"] = "ca-app-pub-1380680048513180/9680715758" // Replace with your AdMob app ID
        
        // Add resource configuration for better indexing
        resourceConfigurations.addAll(listOf("en", "es"))
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            proguardFiles(getDefaultProguardFile("proguard-android.txt"), "proguard-rules.pro")
            
            // Add Bundle configuration for better Play Store indexing
            isShrinkResources = true
        }
    }
    
    bundle {
        language {
            enableSplit = true
        }
        density {
            enableSplit = true
        }
        abi {
            enableSplit = true
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.core:core-ktx:1.10.1")
    implementation("com.google.firebase:firebase-analytics-ktx:21.4.0") // Firebase Analytics dependency
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3") // Add this line
}

apply(plugin = "com.google.gms.google-services") // Apply Google Services plugin