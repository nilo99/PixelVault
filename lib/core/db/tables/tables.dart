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
