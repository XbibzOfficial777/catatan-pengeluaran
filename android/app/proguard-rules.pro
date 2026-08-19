# Flutter engine and generated plugin registration are loaded reflectively.
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep the application entry activity and generated Android embedding hooks.
-keep class com.catat.pengeluaran.** { *; }

# Keep image picker plugin method-channel classes.
-keep class io.flutter.plugins.imagepicker.** { *; }

# The app does not use Play Store deferred components; Flutter references these optionally.
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
