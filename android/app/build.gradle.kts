import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Conditionally apply Google Services plugin only if google-services.json exists
val googleServicesFile = file("google-services.json")
if (googleServicesFile.exists()) {
    apply(plugin = "com.google.gms.google-services")
}

// Load keystore properties
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val hasValidKeystoreProperties = if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
    keystoreProperties.containsKey("keyAlias") &&
    keystoreProperties.containsKey("keyPassword") &&
    keystoreProperties.containsKey("storeFile") &&
    keystoreProperties.containsKey("storePassword")
} else {
    false
}

android {
    namespace = "com.muscleup.muscleup"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.muscleup.muscleup"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        // Always create the release signing config, but only populate it if we have valid properties
        create("release") {
            if (hasValidKeystoreProperties) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Release builds MUST be signed for Play Store uploads
            if (hasValidKeystoreProperties) {
                signingConfig = signingConfigs.getByName("release")
            }
            // Note: If keystore properties are missing, release builds will fail at build time
            // This allows debug builds to proceed without requiring signing configuration
        }
    }
    
    // Validate signing configuration only when building release tasks
    afterEvaluate {
        tasks.configureEach {
            if (name.contains("Release") && (name.contains("Bundle") || name.contains("Assemble"))) {
                if (!hasValidKeystoreProperties) {
                    doFirst {
                        throw GradleException(
                            """
                            ERROR: Release signing configuration is missing or incomplete!
                            
                            To build a signed release bundle, you must:
                            1. Create a keystore file (e.g., android/app/muscleup-release-key.jks)
                            2. Create android/key.properties with:
                               storePassword=YOUR_KEYSTORE_PASSWORD
                               keyPassword=YOUR_KEY_PASSWORD
                               keyAlias=muscleup-key
                               storeFile=muscleup-release-key.jks
                            
                            See PRODUCTION_SIGNING_GUIDE.md for detailed instructions.
                            """
                        )
                    }
                }
            }
        }
    }
}

dependencies {
    // Kotlin Coroutines for async operations
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-play-services:1.7.3")
    // Core library desugaring for flutter_local_notifications
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    
    // Firebase BOM (Bill of Materials) - manages all Firebase library versions
    implementation(platform("com.google.firebase:firebase-bom:33.7.0"))
    
    // Firebase dependencies for native Kotlin code
    implementation("com.google.firebase:firebase-messaging")
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
}

flutter {
    source = "../.."
}
