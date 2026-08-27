# Keep source/line info so release crash traces are still readable.
-keepattributes SourceFile,LineNumberTable

# flutter_foreground_task resolves its Service by the *exact* fully-qualified
# class name hardcoded in AndroidManifest.xml — if R8 renames this class, the
# manifest's hardcoded string no longer matches, and the foreground service
# silently fails to start again (the exact bug fixed earlier this session,
# just reintroduced by minification instead of a missing manifest entry).
-keep class com.pravera.flutter_foreground_task.** { *; }

# libtorrent4j and 7-Zip-JBinding are JNI bridges — native (C/C++) code looks
# up these Java/Kotlin classes and methods by name via JNI, so R8 must not
# rename or strip anything in these packages.
-keep class org.libtorrent4j.** { *; }
-keepclassmembers class org.libtorrent4j.** { *; }
-keep class net.sf.sevenzipjbinding.** { *; }
-keepclassmembers class net.sf.sevenzipjbinding.** { *; }
