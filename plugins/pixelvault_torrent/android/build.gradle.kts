group = "com.pixelvault.pixelvault_torrent"
version = "1.0-SNAPSHOT"

buildscript {
    val kotlinVersion = "2.3.20"
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:9.0.1")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
        // 7-Zip-JBinding-4Android is only published on jitpack.
        maven { url = uri("https://jitpack.io") }
    }
}

plugins {
    id("com.android.library")
}

android {
    namespace = "com.pixelvault.pixelvault_torrent"

    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/kotlin")
        }
        getByName("test") {
            java.srcDirs("src/test/kotlin")
        }
    }

    defaultConfig {
        // libtorrent4j-android requires a modern NDK ABI.
        minSdk = 29

        ndk {
            abiFilters += listOf("arm64-v8a", "armeabi-v7a", "x86_64")
        }
    }

    packaging {
        jniLibs {
            excludes += listOf("META-INF/LICENSE", "META-INF/LICENSE.txt")
        }
    }

    testOptions {
        unitTests {
            isIncludeAndroidResources = true
            all {
                it.useJUnitPlatform()

                it.outputs.upToDateWhen { false }

                it.testLogging {
                    events("passed", "skipped", "failed", "standardOut", "standardError")
                    showStandardStreams = true
                }
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.10.2")
    implementation("androidx.documentfile:documentfile:1.1.0")

    // libtorrent4j
    implementation("org.libtorrent4j:libtorrent4j-android-arm64:2.1.0-39")
    implementation("org.libtorrent4j:libtorrent4j-android-arm:2.1.0-39")
    implementation("org.libtorrent4j:libtorrent4j-android-x86_64:2.1.0-39")

    // 7z extraction
    implementation("com.github.omicronapps:7-Zip-JBinding-4Android:Release-16.02-2.03")

    testImplementation("org.jetbrains.kotlin:kotlin-test")
    testImplementation("org.mockito:mockito-core:5.0.0")
}
