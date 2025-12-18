# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Google Play Core (para Flutter embedding)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# FFmpeg Kit - CRÍTICO para que funcione el procesamiento de video
-keep class com.arthenica.** { *; }
-keep class com.arthenica.ffmpegkit.** { *; }
-dontwarn com.arthenica.**

# Camera plugin
-keep class io.flutter.plugins.camera.** { *; }
-keep class androidx.camera.** { *; }
-dontwarn androidx.camera.**

# Geolocator plugin
-keep class com.baseflow.geolocator.** { *; }
-dontwarn com.baseflow.geolocator.**

# Geocoding plugin
-keep class com.baseflow.geocoding.** { *; }
-dontwarn com.baseflow.geocoding.**

# Permission handler
-keep class com.baseflow.permissionhandler.** { *; }
-dontwarn com.baseflow.permissionhandler.**

# Path provider
-keep class io.flutter.plugins.pathprovider.** { *; }

# Video player
-keep class io.flutter.plugins.videoplayer.** { *; }

# Gal (galería)
-keep class studio.midoridesign.gal.** { *; }

# HTTP
-keep class io.flutter.plugins.urllauncher.** { *; }

# Mantener clases nativas de Kotlin/Java
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

# Mantener información de depuración para stack traces
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
