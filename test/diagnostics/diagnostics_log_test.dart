import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixelvault/core/diagnostics/diagnostics_log.dart';

void main() {
  late Directory dir;
  late File file;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('pv_diagnostics_');
    file = File('${dir.path}/logs/pixelvault.log');
  });

  tearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  DiagnosticsLog logWith({int maxBytes = 256 * 1024}) =>
      DiagnosticsLog(file, maxBytes: maxBytes, clock: () => DateTime.utc(2026, 9, 10, 12, 30));

  test('records a timestamped, categorised entry', () async {
    final log = logWith();
    await log.record('download', 'failed: incomplete');

    expect(await log.read(), '2026-09-10T12:30:00.000Z [download] failed: incomplete\n');
  });

  test('includes a trimmed stack trace when given one', () async {
    final log = logWith();
    await log.record('crash', StateError('boom'), StackTrace.current);

    final content = await log.read();
    expect(content, contains('Bad state: boom'));
    expect(content.split('\n').length, lessThanOrEqualTo(15));
  });

  test('never keeps a source URL, magnet or folder URI', () async {
    final log = logWith();
    await log.record(
      'download',
      'failed for magnet:?xt=urn:btih:deadbeef&dn=Secret at https://mirror.example/roms/game.chd '
          'into content://com.android.externalstorage.documents/tree/primary%3ARoms',
    );

    final content = await log.read();
    expect(content, isNot(contains('magnet:')));
    expect(content, isNot(contains('mirror.example')));
    expect(content, isNot(contains('content://')));
    expect(content, contains('<redacted>'));
  });

  test('keeps entries in the order they were recorded', () async {
    final log = logWith();
    for (var i = 0; i < 20; i++) {
      // Deliberately not awaited: concurrent callers must not interleave.
      log.record('event', 'entry $i');
    }

    final lines = (await log.read()).trim().split('\n');
    expect(lines.map((l) => l.split('] ').last), [for (var i = 0; i < 20; i++) 'entry $i']);
  });

  test('drops the oldest entries once the log outgrows its limit, keeping the newest', () async {
    final log = logWith(maxBytes: 2000);
    for (var i = 0; i < 100; i++) {
      await log.record('event', 'entry number $i with some padding to take up space');
    }

    final content = await log.read();
    expect(content.length, lessThanOrEqualTo(2000));
    expect(content, contains('entry number 99 '));
    expect(content, isNot(contains('entry number 0 ')));
    // Trimming happens on a line boundary, so every kept line is whole.
    for (final line in content.trim().split('\n')) {
      expect(line, startsWith('2026-09-10T'));
    }
  });

  test('reading a log that was never written returns an empty string', () async {
    expect(await logWith().read(), '');
  });

  test('clear empties the log', () async {
    final log = logWith();
    await log.record('event', 'something');
    await log.clear();
    expect(await log.read(), '');
  });

  group('Diagnostics', () {
    test('recording before a log is installed does nothing', () async {
      Diagnostics.record('event', 'ignored');
      expect(await Diagnostics.read(), '');
    });

    test('once installed, records go to that log', () async {
      Diagnostics.install(logWith());
      Diagnostics.record('download', 'attempt 3 failed: incomplete');
      expect(await Diagnostics.read(), contains('[download] attempt 3 failed: incomplete'));
    });
  });
}
