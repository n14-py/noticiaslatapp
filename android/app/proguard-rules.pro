# R8 / ProGuard. Keep rules mínimas para no inflar la RAM (Play Console).
# Los plugins de Flutter ya traen sus consumer-rules.

-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# AdMob / Play services (reflexión)
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.android.gms.common.** { *; }

# In-app purchase / Play Billing
-keep class com.android.billingclient.** { *; }
-keep class com.android.vending.billing.** { *; }

# Geolocator
-keep class com.baseflow.geolocator.** { *; }

-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
