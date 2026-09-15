package com.pixelvault.pixelvault

import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {

    /**
     * Called when Flutter has nothing left to pop and would otherwise finish
     * this activity — Back on the Plataformas tab.
     *
     * Finishing destroys the Flutter engine, and with it every HTTP download
     * running in Dart, while the foreground download service keeps the
     * process alive. Reopening from recents then built a second engine inside
     * that same process: a fresh-looking app with no queue and no history,
     * whose database writes collided with the dead engine's connection until
     * the app was force-stopped. Sending the task to the background is what
     * the home button does, and it keeps downloads running.
     */
    override fun popSystemNavigator(): Boolean {
        moveTaskToBack(true)
        return true
    }
}
