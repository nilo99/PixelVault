import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Keeps the app process (and with it the libtorrent4j session + in-flight
/// HTTP downloads) alive while backgrounded — replaces Milou's
/// `DownloadForegroundService` + manual wakelock. The download logic itself
/// still runs on the main Dart isolate via `DownloadManager`; this handler
/// only needs to exist so `flutter_foreground_task` has a valid callback.
class DownloadForegroundTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp('/downloads');
  }
}

@pragma('vm:entry-point')
void startForegroundTaskCallback() {
  FlutterForegroundTask.setTaskHandler(DownloadForegroundTaskHandler());
}

void initForegroundTask() {
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'pixelvault_downloads',
      channelName: 'Downloads',
      channelDescription: 'Mantém os downloads a decorrer em segundo plano.',
      onlyAlertOnce: true,
    ),
    iosNotificationOptions: const IOSNotificationOptions(),
    foregroundTaskOptions: ForegroundTaskOptions(
      eventAction: ForegroundTaskEventAction.nothing(),
      allowWakeLock: true,
    ),
  );
}
