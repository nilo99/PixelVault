import 'dart:async';
import 'dart:io';

/// A small, rotating, on-device error log the user can copy and send.
///
/// The app runs on handhelds nobody debugging it can attach to. When
/// something goes wrong there, the options were guessing or asking the user
/// to set up adb. This keeps the most recent unhandled errors and download
/// failures on the device instead, readable from Settings.
///
/// Never pass a source URL or magnet as a message: callers log stable codes
/// and error types. [redact] strips anything that still looks like one, as a
/// backstop.
class DiagnosticsLog {
  DiagnosticsLog(this._file, {this.maxBytes = 256 * 1024, DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final File _file;

  /// When the file grows past this, the oldest half is dropped.
  final int maxBytes;

  final DateTime Function() _clock;

  /// Writes are chained so entries keep their order and never interleave.
  Future<void> _pending = Future.value();

  static final _sensitive = RegExp(r'(magnet:\?\S+|https?://\S+|content://\S+)', caseSensitive: false);

  static const _maxStackLines = 12;

  /// Appends one entry. Never throws: a failure to write the log must not
  /// become a second error on top of the one being logged.
  Future<void> record(String category, Object message, [StackTrace? stack]) {
    final entry = StringBuffer()
      ..write(_clock().toUtc().toIso8601String())
      ..write(' [')
      ..write(category)
      ..write('] ')
      ..write(redact('$message'));
    if (stack != null) {
      entry
        ..write('\n')
        ..write(redact(stack.toString().split('\n').take(_maxStackLines).join('\n')));
    }
    entry.write('\n');

    return _pending = _pending.then((_) => _append(entry.toString())).catchError((Object _) {});
  }

  /// Replaces URLs, magnets and SAF URIs with a placeholder.
  static String redact(String text) => text.replaceAll(_sensitive, '<redacted>');

  Future<void> _append(String entry) async {
    await _file.parent.create(recursive: true);
    await _file.writeAsString(entry, mode: FileMode.append, flush: true);
    if (await _file.length() <= maxBytes) return;

    // Keep the newest half: the most recent failure is the one worth sending.
    final content = await _file.readAsString();
    final cut = (content.length - maxBytes ~/ 2).clamp(0, content.length);
    final lineStart = content.indexOf('\n', cut);
    final kept = lineStart == -1 ? content.substring(cut) : content.substring(lineStart + 1);
    await _file.writeAsString(kept, flush: true);
  }

  /// The whole log, or an empty string if nothing has been recorded.
  Future<String> read() async {
    await _pending;
    try {
      return await _file.exists() ? await _file.readAsString() : '';
    } catch (_) {
      return '';
    }
  }

  Future<void> clear() async {
    await _pending;
    try {
      if (await _file.exists()) await _file.delete();
    } catch (_) {
      // Best-effort.
    }
  }
}

/// The app-wide [DiagnosticsLog], installed once at startup.
///
/// A static facade rather than a provider, because the places that most need
/// to record something — `FlutterError.onError`, the root zone, a download
/// worker unwinding — have no `Ref` to read one from. Until [install] runs,
/// and in tests, recording does nothing.
abstract final class Diagnostics {
  static DiagnosticsLog? _log;

  static void install(DiagnosticsLog log) => _log = log;

  static void record(String category, Object message, [StackTrace? stack]) {
    unawaited(_log?.record(category, message, stack));
  }

  /// Everything recorded so far, or an empty string when nothing is installed.
  static Future<String> read() => _log?.read() ?? Future.value('');
}
