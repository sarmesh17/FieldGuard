# ---------------------------------------------------------------------------
# R8 / ProGuard keep rules for the release (shrunk) build.
#
# Flutter's own engine rules (io.flutter.**) are merged automatically by the
# Flutter Gradle plugin when minification is enabled. The rules below cover
# plugins that resolve classes via reflection / JNI and would otherwise be
# stripped by R8, causing release-only crashes. Keep them broad on purpose —
# the dominant size win comes from native-lib + resource shrinking, not from
# trimming these few packages.
# ---------------------------------------------------------------------------

# Flutter embedding (belt-and-suspenders; usually auto-added).
-keep class io.flutter.** { *; }
-dontwarn io.flutter.embedding.**

# --- Mapbox Maps SDK: JNI + reflection-heavy native renderer ---------------
-keep class com.mapbox.** { *; }
-dontwarn com.mapbox.**

# --- flutter_local_notifications: (de)serialises details via Gson and -------
#     registers receivers by name. Rules taken from the plugin README.
-keep class com.dexterous.** { *; }
-keepattributes *Annotation*, Signature, InnerClasses, EnclosingMethod
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**

# --- flutter_secure_storage: AndroidX Security Crypto / Tink (reflection) ---
-keep class androidx.security.crypto.** { *; }
-keep class com.google.crypto.tink.** { *; }
-dontwarn com.google.crypto.tink.**

# --- flutter_background_service: foreground Service resolved by class name --
-keep class id.flutter.flutter_background_service.** { *; }

# --- flutter_jailbreak_detection: root checks via rootbeer + reflection -----
-keep class com.scottyab.rootbeer.** { *; }
-dontwarn com.scottyab.rootbeer.**

# --- OkHttp / Okio (pulled in transitively; reflection on annotations) ------
-keep class okhttp3.** { *; }
-keep class okio.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# --- Firebase Cloud Messaging (FCM) -----------------------------------------
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# --- Keep every JNI native binding (matched by name from native code) -------
-keepclasseswithmembernames class * {
    native <methods>;
}
