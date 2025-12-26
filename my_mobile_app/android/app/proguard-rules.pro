##############################
# Flutter Required Rules
##############################

# Keep all Flutter classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.** { *; }

# Do not warn about Flutter
-dontwarn io.flutter.**

##############################
# Google Tink Cryptography Fix
##############################

# Keep all Tink classes (critical)
-keep class com.google.crypto.tink.** { *; }
-dontwarn com.google.crypto.tink.**

##############################
# JavaX Annotations Fix
##############################

# Keep JavaX (used by Tink)
-keep class javax.annotation.** { *; }
-dontwarn javax.annotation.**

##############################
# ErrorProne Annotations Fix
##############################

# Keep Google ErrorProne annotations (used internally by many libs)
-keep class com.google.errorprone.annotations.** { *; }
-dontwarn com.google.errorprone.annotations.**

##############################
# JSR 305 Fix (Nullable annotations)
##############################

-dontwarn org.checkerframework.**
-keep class org.checkerframework.** { *; }

##############################
# Kotlin reflection and metadata
##############################

-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**

##############################
# OkHttp / Retrofit (if used)
##############################

-dontwarn okhttp3.**
-keep class okhttp3.** { *; }

##############################
# Prevent removing model classes
##############################
-keep class com.example.** { *; }
