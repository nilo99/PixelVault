import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing — see `android/key.properties` (git-ignored). Falls back to
// the debug key if the file is missing (e.g. a fresh checkout/CI without the
// keystore) so `flutter build apk --release` doesn't hard-fail; only a real
// distributable release build needs the real file present.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.pixelvault.pixelvault"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.pixelvault.pixelvault"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // libtorrent4j-android requires a modern NDK ABI; matches the minSdk
        // Milou (the Kotlin app this is ported from) was tested against.
        minSdk = 29
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // ABI filtering is driven by `flutter build apk --split-per-abi`
        // (android.splits.abi) instead of an explicit ndk.abiFilters block —
        // Gradle rejects having both configured at once. libtorrent4j ships
        // arm64-v8a/armeabi-v7a/x86_64 native libs; without --split-per-abi
        // a universal APK bundling all three is produced instead.
    }

    packagingOptions {
        jniLibs {
            excludes += listOf("META-INF/LICENSE", "META-INF/LICENSE.txt")
        }
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                // Resolved relative to `android/` (where key.properties itself
                // lives), not `android/app/` — `file()` here would resolve
                // relative to this module instead.
                storeFile = keystoreProperties["storeFile"]?.let { rootProject.file(it) }
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Real upload key when `android/key.properties` is present (see
            // above); falls back to the debug key otherwise so a checkout
            // without the keystore can still produce a (non-distributable)
            // release build.
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
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
