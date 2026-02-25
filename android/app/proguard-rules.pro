# Flutter/Dart
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Google Sign-In
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Keep Gson / Firestore serialization
-keepattributes Signature
-keepattributes *Annotation*

# Prevent R8 from removing Google Play Services error classes
-keep class com.google.android.gms.common.api.ApiException { *; }
