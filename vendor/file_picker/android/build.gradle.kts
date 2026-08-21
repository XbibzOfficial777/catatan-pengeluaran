import org.jetbrains.kotlin.gradle.dsl.JvmTarget
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

group = "com.mr.flutter.plugin.filepicker"
version = "1.0-SNAPSHOT"

plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "com.mr.flutter.plugin.filepicker"
    compileSdk = 36

    defaultConfig {
        minSdk = 21
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        consumerProguardFiles("proguard-rules.pro")
    }

    lint {
        disable += "InvalidPackage"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }


}

tasks.withType<KotlinCompile>().configureEach {
    compilerOptions.jvmTarget.set(JvmTarget.JVM_17)
}

dependencies {
    implementation("androidx.core:core:1.15.0")
    implementation("androidx.core:core-ktx:1.15.0")
    implementation("androidx.annotation:annotation:1.9.1")
    implementation("androidx.lifecycle:lifecycle-runtime:2.8.7")
    implementation("org.apache.tika:tika-core:3.2.0")
}
