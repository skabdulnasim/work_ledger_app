# Keep Razorpay and Google Pay related classes
-keep class com.google.android.apps.nbu.paisa.** { *; }
-keep class proguard.annotation.** { *; }
-keep class com.razorpay.** { *; }

# Keep annotations
-keepattributes *Annotation*

# Prevent R8 from removing Wallet, WalletUtils, etc.
-dontwarn com.google.android.apps.nbu.paisa.**
-dontwarn proguard.annotation.**
