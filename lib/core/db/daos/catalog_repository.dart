import 'package:drift/drift.dart';

import '../../models/console_x.dart';
import '../../models/url_entry.dart';
import '../../security/urls_cipher_holder.dart';
import '../database.dart';

/// Manufacturer/console CRUD — port of Milou's `ManufacturerDao` + `ConsoleDao`.
class CatalogRepository {
  CatalogRepository(this.db);

  final AppDatabase db;

  Future<void> clearAll() async {
    await db.transaction(() async {
      await db.delete(db.consoles).go();
      await db.delete(db.manufacturers).go();
    });
  }

  Future<void> insertManufacturers(List<ManufacturersCompanion> rows) {
    return db.batch((batch) => batch.insertAll(db.manufacturers, rows, mode: InsertMode.insertOrReplace));
  }

  Future<void> insertConsoles(List<ConsolesCompanion> rows) {
    return db.batch((batch) => batch.insertAll(db.consoles, rows, mode: InsertMode.insertOrReplace));
  }

  Future<void> upsertManufacturer(ManufacturersCompanion row) {
    return db.into(db.manufacturers).insertOnConflictUpdate(row);
  }

  Future<void> upsertConsole(ConsolesCompanion row) {
    return db.into(db.consoles).insertOnConflictUpdate(row);
  }

  Future<void> deleteManufacturer(String id) {
    return (db.delete(db.manufacturers)..where((m) => m.id.equals(id))).go();
  }

  Future<void> deleteConsole(String id) {
    return (db.delete(db.consoles)..where((c) => c.id.equals(id))).go();
  }

  Stream<List<Manufacturer>> watchManufacturers() {
    return (db.select(db.manufacturers)..orderBy([(m) => OrderingTerm.asc(m.name)])).watch();
  }

  Future<List<Console>> getConsolesForManufacturer(String manufacturerId) {
    return (db.select(db.consoles)..where((c) => c.manufacturerId.equals(manufacturerId))).get();
  }

  Future<Console?> getConsoleById(String consoleId) {
    return (db.select(db.consoles)..where((c) => c.id.equals(consoleId))).getSingleOrNull();
  }

  Stream<List<Console>> watchAllConsoles() {
    return (db.select(db.consoles)..orderBy([(c) => OrderingTerm.asc(c.name)])).watch();
  }

  static String _encodeUrls(List<UrlEntry> urls) => UrlsCipherHolder.instance.encode(urls);

  /// Adds [entry] to every console in [consoleIds] — the same source (e.g. a
  /// pack torrent covering several platforms) can be attached to more than
  /// one console at once instead of re-typing the URL per console. A console
  /// that already has this exact `url` is left untouched instead of getting
  /// a duplicate entry — relevant mainly for the link-install flow, where
  /// tapping "Instalar" more than once for the same source must be harmless.
  Future<void> addUrlToConsoles(List<String> consoleIds, UrlEntry entry) async {
    await db.transaction(() async {
      for (final consoleId in consoleIds) {
        final console = await getConsoleById(consoleId);
        if (console == null) continue;
        if (console.urls.any((u) => u.url == entry.url)) continue;
        final updated = [...console.urls, entry];
        await upsertConsole(ConsolesCompanion(
          id: Value(console.id),
          name: Value(console.name),
          manufacturerId: Value(console.manufacturerId),
          urlsJson: Value(_encodeUrls(updated)),
        ));
      }
    });
  }

  Future<void> removeUrlFromConsole(String consoleId, UrlEntry entry) async {
    await db.transaction(() async {
      final console = await getConsoleById(consoleId);
      if (console == null) return;
      final updated = console.urls.where((u) => u.url != entry.url).toList();
      await upsertConsole(ConsolesCompanion(
        id: Value(console.id),
        name: Value(console.name),
        manufacturerId: Value(console.manufacturerId),
        urlsJson: Value(_encodeUrls(updated)),
      ));
    });
  }

  /// Overwrites a console's whole url list — used by [ScrapeOrchestrator]
  /// after a scrape to persist each source's updated `lastSyncedAt`.
  Future<void> updateConsoleUrls(String consoleId, List<UrlEntry> urls) async {
    await db.transaction(() async {
      final console = await getConsoleById(consoleId);
      if (console == null) return;
      await upsertConsole(ConsolesCompanion(
        id: Value(console.id),
        name: Value(console.name),
        manufacturerId: Value(console.manufacturerId),
        urlsJson: Value(_encodeUrls(urls)),
      ));
    });
  }
}
