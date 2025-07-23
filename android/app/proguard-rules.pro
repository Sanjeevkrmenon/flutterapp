-keep class com.sun.jna.* { *; }
-keepclassmembers class * extends com.sun.jna.* { public *; }
# JNA Desktop Dependencies - Ignore Desktop Java Classes Not On Android
-dontwarn java.awt.**
-dontwarn javax.swing.**
-dontwarn sun.awt.**
-dontwarn com.sun.jna.**
-keep class com.sun.jna.** { *; }
-keep class * extends com.sun.jna.** { *; }