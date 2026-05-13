plugins {
    id 'com.android.application'
    id 'kotlin-android'
    id 'com.chaquo.python'  // ← AGGIUNGI QUESTA RIGA
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace 'com.example.test1'
    compileSdk 34

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = '1.8'
    }

    defaultConfig {
        applicationId "com.example.test1"
        minSdk 24
        targetSdk 34
        versionCode 1
        versionName "1.0"
        
        ndk {
            abiFilters "armeabi-v7a", "arm64-v8a"
        }
        
        python {
            version "3.8"
            pip {
                install "onnxruntime==1.16.0"
                install "numpy==1.24.3"
                install "opencv-python-headless==4.8.1.78"
                install "Pillow==10.0.0"
            }
        }
    }

    buildTypes {
        release {
            signingConfig signingConfigs.debug
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation "org.jetbrains.kotlin:kotlin-stdlib-jdk7:$kotlin_version"
}

allprojects {
    repositories {
        maven { url = uri("https://maven.aliyun.com/repository/google") }
        maven { url = uri("https://maven.aliyun.com/repository/jcenter") }
        maven { url = uri("https://maven.aliyun.com/repository/public") }
        google()
        mavenCentral()
    }
}