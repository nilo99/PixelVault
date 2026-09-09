import 'package:drift/drift.dart';

/// Port of Milou's Room schema (ManufacturerEntity / ConsoleEntity /
/// DownloadableFileEntity / FileTagEntity) — see `design/gengar_design_system.md`
/// sibling doc for the rest of the design system; this is the data layer.
class Manufacturers extends Table {
  TextColumn get id => text()(); // e.g. "nintendo"
  TextColumn get name => text()(); // e.g. "Nintendo"

  @override
  Set<Column> get primaryKey => {id};
}

class Consoles extends Table {
  TextColumn get id => text()(); // e.g. "nintendo_gameboy_advance"
  TextColumn get name => text()(); // e.g. "Gameboy Advance"
  TextColumn get manufacturerId =>
      text().references(Manufacturers, #id, onDelete: KeyAction.cascade)();
  TextColumn get urlsJson => text()(); // JSON-encoded List<UrlEntry>

  @override
  Set<Column> get primaryKey => {id};
}

class DownloadableFiles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get fileName => text()();
  TextColumn get consoleId =>
      text().references(Consoles, #id, onDelete: KeyAction.cascade)();
  TextColumn get downloadUrl => text()();
  IntColumn get fileSize => integer().withDefault(const Constant(0))();
  TextColumn get fileExtension => text().withDefault(const Constant(''))();
  IntColumn get torrentFileIndex => integer().nullable()();
  TextColumn get torrentMagnet => text().nullable()();
}

class FileTags extends Table {
  IntColumn get fileId =>
      integer().references(DownloadableFiles, #id, onDelete: KeyAction.cascade)();
  TextColumn get tag => text()();

  @override
  Set<Column> get primaryKey => {fileId, tag};
}

/// Every download the user has ever started — in progress, finished or
/// failed. Before this table existed the whole download list lived only in
/// `DownloadProgressTrackerNotifier`'s in-memory `List<DownloadItem>`, so
/// killing the app (or an OS-initiated kill under memory pressure, which is
/// routine while a multi-GB ROM downloads) lost the queue, the progress and
/// the entire history with it.
///
/// Deliberately **not** a foreign key onto [DownloadableFiles]: a catalog
/// rescan calls `deleteFilesByConsoleId` and re-inserts every row, which
/// would cascade the user's history away. The columns the UI needs are
/// snapshotted here instead, so a finished download stays readable even
/// after its source is removed. [catalogFileId] keeps the (best-effort) link
/// back to the live catalog row for retrying; it is not enforced, because
/// SQLite reuses autoincrement rowids after a bulk delete and the id may
/// well point at a different file by the time history is read back.
class Downloads extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// The `DownloadableFiles.id` this download came from, at the time it
  /// started. Not unique and not a foreign key — see the class doc.
  IntColumn get catalogFileId => integer()();

  TextColumn get name => text()();
  TextColumn get fileName => text()();
  TextColumn get consoleId => text()();
  TextColumn get consoleName => text().withDefault(const Constant(''))();
  TextColumn get downloadUrl => text()();
  IntColumn get fileSize => integer().withDefault(const Constant(0))();
  TextColumn get fileExtension => text().withDefault(const Constant(''))();
  IntColumn get torrentFileIndex => integer().nullable()();
  TextColumn get torrentMagnet => text().nullable()();

  /// `DownloadStatus.name`, stored as text so adding an enum value later
  /// doesn't renumber existing rows.
  TextColumn get status => text()();
  RealColumn get progress => real().withDefault(const Constant(0))();
  IntColumn get downloadedBytes => integer().withDefault(const Constant(0))();

  /// Where the file actually landed. [destinationUri] is the SAF document
  /// tree URI (opaque, for programmatic reopening); [destinationLabel] is the
  /// human-readable path shown in the Downloads screen — "can't see where it
  /// downloaded to" was a direct consequence of storing neither.
  TextColumn get destinationUri => text().withDefault(const Constant(''))();
  TextColumn get destinationLabel => text().withDefault(const Constant(''))();

  /// The name actually written at the destination, which differs from
  /// [fileName] whenever an archive was auto-extracted.
  TextColumn get savedFileName => text().withDefault(const Constant(''))();

  /// Stable, non-sensitive failure reason (see `DownloadFailureReason`) —
  /// never the raw exception, which can carry a magnet/URL.
  TextColumn get failureReason => text().nullable()();

  /// Absolute path of the partially-downloaded staging file, so an
  /// interrupted HTTP download resumes from where it stopped instead of
  /// starting over.
  TextColumn get stagingPath => text().withDefault(const Constant(''))();

  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get completedAt => integer().nullable()();
}
