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

        // libtorrent4j ships arm64-v8a/armeabi-v7a/x86_64 native libs, so a
        // plain `flutter build apk` would bundle all three into one universal
        // APK. The `androidComponents` block below trims x86_64 back out of
        // release builds — see the note there. Do not combine that with
        // `--split-per-abi`
        // (android.splits.abi): Gradle rejects having both configured at once.
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

// x86_64 only serves emulators and ChromeOS — no shipping phone uses it, and
// libtorrent4j's copy of it alone is ~40MB of a ~116MB universal APK. Excluded
// per-variant (rather than via `defaultConfig.ndk.abiFilters`, which AGP does
// not apply to jniLibs coming from dependency AARs) so debug builds keep every
// ABI and `flutter run` still works on an x86_64 emulator — only
// `flutter run --release` would now fail there.
androidComponents {
    onVariants(selector().withBuildType("release")) { variant ->
        variant.packaging.jniLibs.excludes.add("lib/x86_64/**")
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
