# Flutter Wrapper & Engine
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class io.flutter.embedding.** { *; }

# App Package & MainActivity
-keep class com.bikeparkgo.bikeparkgo.** { *; }

# Multidex
-keep class androidx.multidex.** { *; }

# Preserve JNI annotations & attributes
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes SourceFile,LineNumberTable
-dontwarn io.flutter.**
-dontwarn androidx.**
