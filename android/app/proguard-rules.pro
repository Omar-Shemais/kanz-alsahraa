##############################################
# Flutter + Dart
##############################################
# Keep Flutter classes
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.app.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }


##############################################
# Firebase
##############################################
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
-keepattributes Signature
-keepattributes *Annotation*

##############################################
# Google Play Services / Ads
##############################################
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# AdMob / MobileAds
-keep public class com.google.android.gms.ads.** { *; }
-keep public class com.google.ads.** { *; }

##############################################
# flutter_inappwebview
##############################################
-keep class com.pichillilorenzo.flutter_inappwebview.** { *; }
-dontwarn com.pichillilorenzo.flutter_inappwebview.**

##############################################
# Android 14 Back Navigation API (fix BackEvent issue)
##############################################
-keep class android.window.** { *; }
-dontwarn android.window.**

##############################################
# Kotlin / Coroutines
##############################################
-keep class kotlin.Metadata { *; }
-keep class kotlinx.coroutines.** { *; }
-dontwarn kotlinx.coroutines.**

##############################################
# Misc - Safe Defaults
##############################################
-dontwarn java.lang.invoke.*
-dontwarn javax.annotation.**
-dontwarn org.jetbrains.annotations.**
-keepattributes InnerClasses,EnclosingMethod
