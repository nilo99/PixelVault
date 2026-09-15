import 'package:drift/drift.dart';

import '../../models/downloadable_file.dart';
import '../../scraping/rom_title.dart';
import '../database.dart';

/// One filter clause plus the variables it binds, so the flat and grouped
/// search queries build their `WHERE` from exactly the same source.
typedef _Filter = ({String sql, List<Variable> vars});

/// Port of Milou's `DownloadableFileDao` — the composite search query is
/// kept as raw SQL (rather than Drift's query builder) so the filtering
/// semantics stay identical to the original: match-any-tag vs match-all-tag,
/// manufacturer/console/tag/pagination all combined in one query.
class DownloadableFileRepository {
  DownloadableFileRepository(this.db);

  final AppDatabase db;

  /// Escapes SQLite `LIKE` wildcards (`%`, `_`) in user-typed search terms so
  /// e.g. searching for a literal underscore doesn't match any single
  /// character. Paired with `ESCAPE '\'` in the query.
  static String _escapeLikePattern(String query) {
    return query.replaceAll('\\', '\\\\').replaceAll('%', '\\%').replaceAll('_', '\\_');
  }

  /// Live count of indexed files per console — lets the Sources screen show
  /// "X jogos indexados" (and distinguish "has a source" from "has actually
  /// been scanned"), auto-updating whenever a rescan inserts/removes rows.
  Stream<Map<String, int>> watchFileCountsByConsole() {
    return db.customSelect(
      'SELECT console_id, COUNT(*) as cnt FROM downloadable_files GROUP BY console_id',
      readsFrom: {db.downloadableFiles},
    ).watch().map((rows) => {
          for (final row in rows) row.read<String>('console_id'): row.read<int>('cnt'),
        });
  }

  /// Live total indexed file size per console, in bytes — feeds the
  /// Plataformas list's "{count} jogos · {size}" meta line.
  Stream<Map<String, int>> watchFileSizesByConsole() {
    return db.customSelect(
      'SELECT console_id, COALESCE(SUM(file_size), 0) as total FROM downloadable_files GROUP BY console_id',
      readsFrom: {db.downloadableFiles},
    ).watch().map((rows) => {
          for (final row in rows) row.read<String>('console_id'): row.read<int>('total'),
        });
  }

  /// Inserts every file and its tags in one transaction.
  ///
  /// The tag rows for *all* files are collected and written as a single
  /// batch at the end rather than one batch per file — a pack torrent can
  /// carry tens of thousands of entries, and the old shape issued one extra
  /// batch round-trip per file on top of the insert itself.
  ///
  /// A file inserted without a group key gets one derived from its name, so
  /// search can group it whichever code path inserted it.
  Future<void> insertFilesWithTags(
    List<DownloadableFilesCompanion> files,
    List<List<String>> tagsPerFile,
  ) async {
    assert(files.length == tagsPerFile.length);
    await db.transaction(() async {
      final tagRows = <FileTagsCompanion>[];
      for (var i = 0; i < files.length; i++) {
        final inserted = await db.into(db.downloadableFiles).insertReturning(_withGroupKey(files[i]));
        for (final tag in tagsPerFile[i]) {
          tagRows.add(FileTagsCompanion.insert(fileId: inserted.id, tag: tag));
        }
      }
      if (tagRows.isEmpty) return;
      await db.batch((batch) {
        batch.insertAll(db.fileTags, tagRows, mode: InsertMode.insertOrReplace);
      });
    });
  }

  static DownloadableFilesCompanion _withGroupKey(DownloadableFilesCompanion file) {
    if (file.groupKey.present && file.groupKey.value.isNotEmpty) return file;
    if (!file.name.present) return file;
    return file.copyWith(groupKey: Value(RomTitle.key(file.name.value)));
  }

  Future<void> deleteFilesByConsoleId(String consoleId) {
    // ON DELETE CASCADE (foreign_keys pragma is enabled in beforeOpen) takes
    // care of the file_tags rows automatically.
    return (db.delete(db.downloadableFiles)..where((f) => f.consoleId.equals(consoleId))).go();
  }

  Future<int> getFilesCount() async {
    final count = db.downloadableFiles.id.count();
    final query = db.selectOnly(db.downloadableFiles)..addColumns([count]);
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  /// The shared `WHERE` body for both search shapes: free-text match,
  /// manufacturer, console set and tag set (any-of vs all-of).
  _Filter _buildFilter({
    required String query,
    String? manufacturer,
    List<String> consoleIds = const [],
    List<String> tags = const [],
    bool matchAllTags = false,
  }) {
    final vars = <Variable>[];
    final sql = StringBuffer();

    sql.write("(? = '*' OR df.name LIKE '%' || ? || '%' ESCAPE '\\')\n");
    vars.add(Variable(query));
    vars.add(Variable(_escapeLikePattern(query)));

    sql.write('  AND (? IS NULL OR m.name = ?)\n');
    vars.add(Variable(manufacturer));
    vars.add(Variable(manufacturer));

    if (consoleIds.isEmpty) {
      sql.write('  AND (? = 0 OR 1=0)\n');
      vars.add(const Variable(0));
    } else {
      final placeholders = List.filled(consoleIds.length, '?').join(',');
      sql.write('  AND (? = 0 OR df.console_id IN ($placeholders))\n');
      vars.add(Variable(consoleIds.length));
      vars.addAll(consoleIds.map(Variable.new));
    }

    if (tags.isEmpty) {
      sql.write('  AND (? = 0 OR 1=0)\n');
      vars.add(const Variable(0));
    } else {
      final placeholders = List.filled(tags.length, '?').join(',');
      sql.write('''
  AND (? = 0 OR df.id IN (
        SELECT t2.file_id
        FROM file_tags t2
        WHERE t2.tag IN ($placeholders)
        GROUP BY t2.file_id
        HAVING (? = 0 AND COUNT(DISTINCT t2.tag) >= 1)
           OR (? = 1 AND COUNT(DISTINCT t2.tag) = ?)
  ))
''');
      vars.add(Variable(tags.length));
      vars.addAll(tags.map(Variable.new));
      vars.add(Variable(matchAllTags ? 1 : 0));
      vars.add(Variable(matchAllTags ? 1 : 0));
      vars.add(Variable(tags.length));
    }

    return (sql: sql.toString(), vars: vars);
  }

  Future<List<DownloadableFileWithTags>> queryFilesWithTags({
    required String query,
    String? manufacturer,
    List<String> consoleIds = const [],
    List<String> tags = const [],
    bool matchAllTags = false,
    bool sortAsc = true,
    int limit = 100,
    int offset = 0,
  }) async {
    final filter = _buildFilter(
      query: query,
      manufacturer: manufacturer,
      consoleIds: consoleIds,
      tags: tags,
      matchAllTags: matchAllTags,
    );

    final rows = await db.customSelect(
      '''
SELECT df.id, df.name, df.file_name, df.console_id, df.download_url, df.file_size,
       df.file_extension, df.torrent_file_index, df.torrent_magnet,
       GROUP_CONCAT(t.tag, '|') as tags
FROM downloadable_files df
LEFT JOIN file_tags t ON df.id = t.file_id
JOIN consoles c ON df.console_id = c.id
JOIN manufacturers m ON c.manufacturer_id = m.id
WHERE ${filter.sql}
GROUP BY df.id, df.name, df.file_name, df.console_id, df.download_url, df.file_size,
         df.file_extension, df.torrent_file_index, df.torrent_magnet
ORDER BY
    CASE WHEN ? = 1 THEN df.name END ASC,
    CASE WHEN ? = 0 THEN df.name END DESC
LIMIT ? OFFSET ?
''',
      variables: [
        ...filter.vars,
        Variable(sortAsc ? 1 : 0),
        Variable(sortAsc ? 1 : 0),
        Variable(limit),
        Variable(offset),
      ],
      readsFrom: {db.downloadableFiles, db.fileTags, db.consoles, db.manufacturers},
    ).get();

    return rows.map(_toFile).toList();
  }

  /// Search, grouped by game instead of one flat row per file.
  ///
  /// A group is one game on one console: every region, revision and format
  /// of it, joined on `group_key` (see `RomTitle.key`). Searching "god of
  /// war" gives God of War and God of War II as two entries, each holding its
  /// `.iso`, `.7z` and `.chd` files from every region. Grouping used to be on
  /// the stored name, which still carried the extension, so every format of
  /// a game came back as a separate entry.
  ///
  /// Pagination runs over groups, so a game's files are never split across
  /// pages. Two round trips: one for the page of groups, one for every file
  /// inside them.
  Future<List<DownloadableFileGroup>> queryGroupedFiles({
    required String query,
    String? manufacturer,
    List<String> consoleIds = const [],
    List<String> tags = const [],
    bool matchAllTags = false,
    bool sortAsc = true,
    int limit = 60,
    int offset = 0,
  }) async {
    final filter = _buildFilter(
      query: query,
      manufacturer: manufacturer,
      consoleIds: consoleIds,
      tags: tags,
      matchAllTags: matchAllTags,
    );

    final groupRows = await db.customSelect(
      '''
SELECT df.console_id AS console_id,
       df.group_key AS group_key,
       MIN(df.name) AS title,
       COUNT(DISTINCT df.id) AS variant_count,
       SUM(df.file_size) AS total_size
FROM downloadable_files df
JOIN consoles c ON df.console_id = c.id
JOIN manufacturers m ON c.manufacturer_id = m.id
WHERE ${filter.sql}
GROUP BY df.console_id, df.group_key
ORDER BY
    CASE WHEN ? = 1 THEN title END ASC,
    CASE WHEN ? = 0 THEN title END DESC,
    df.console_id ASC
LIMIT ? OFFSET ?
''',
      variables: [
        ...filter.vars,
        Variable(sortAsc ? 1 : 0),
        Variable(sortAsc ? 1 : 0),
        Variable(limit),
        Variable(offset),
      ],
      readsFrom: {db.downloadableFiles, db.fileTags, db.consoles, db.manufacturers},
    ).get();

    if (groupRows.isEmpty) return const [];

    final keys = groupRows.map((r) => r.read<String>('group_key')).toSet().toList();
    final placeholders = List.filled(keys.length, '?').join(',');
    final fileRows = await db.customSelect(
      '''
SELECT df.id, df.name, df.file_name, df.console_id, df.download_url, df.file_size,
       df.file_extension, df.torrent_file_index, df.torrent_magnet, df.group_key,
       GROUP_CONCAT(t.tag, '|') as tags
FROM downloadable_files df
LEFT JOIN file_tags t ON df.id = t.file_id
JOIN consoles c ON df.console_id = c.id
JOIN manufacturers m ON c.manufacturer_id = m.id
WHERE ${filter.sql}
  AND df.group_key IN ($placeholders)
GROUP BY df.id, df.name, df.file_name, df.console_id, df.download_url, df.file_size,
         df.file_extension, df.torrent_file_index, df.torrent_magnet, df.group_key
ORDER BY df.name ASC, df.file_size DESC, df.file_name ASC
''',
      variables: [...filter.vars, ...keys.map(Variable.new)],
      readsFrom: {db.downloadableFiles, db.fileTags, db.consoles, db.manufacturers},
    ).get();

    // A key can repeat across consoles on the page, so files are matched to
    // their group by console as well as by key.
    final byGroup = <String, List<DownloadableFileWithTags>>{};
    for (final row in fileRows) {
      final id = DownloadableFileGroup.idFor(row.read<String>('console_id'), row.read<String>('group_key'));
      byGroup.putIfAbsent(id, () => []).add(_toFile(row));
    }

    return [
      for (final row in groupRows)
        DownloadableFileGroup(
          key: row.read<String>('group_key'),
          consoleId: row.read<String>('console_id'),
          title: row.read<String>('title'),
          variantCount: row.read<int>('variant_count'),
          totalSize: row.read<int>('total_size'),
          variants: byGroup[DownloadableFileGroup.idFor(
                row.read<String>('console_id'),
                row.read<String>('group_key'),
              )] ??
              const [],
        ),
    ];
  }

  Future<List<String>> getAvailableTags({
    required String query,
    String? manufacturer,
    List<String> consoleIds = const [],
  }) async {
    final filter = _buildFilter(
      query: query,
      manufacturer: manufacturer,
      consoleIds: consoleIds,
    );
    final rows = await db.customSelect(
      '''
SELECT DISTINCT t.tag
FROM file_tags t
JOIN downloadable_files df ON t.file_id = df.id
JOIN consoles c ON df.console_id = c.id
JOIN manufacturers m ON c.manufacturer_id = m.id
WHERE ${filter.sql}
ORDER BY t.tag ASC
''',
      variables: filter.vars,
      readsFrom: {db.fileTags, db.downloadableFiles, db.consoles, db.manufacturers},
    ).get();
    return rows.map((r) => r.read<String>('tag')).toList();
  }

  Future<List<ConsoleWithFileCount>> getConsolesWithFiles({
    required String query,
    String? manufacturer,
  }) async {
    final rows = await db.customSelect(
      '''
SELECT DISTINCT c.id, c.name, c.manufacturer_id, c.urls_json, COUNT(df.id) as fileCount,
  COALESCE(SUM(df.file_size), 0) as totalSize
FROM consoles c
JOIN downloadable_files df ON c.id = df.console_id
JOIN manufacturers m ON c.manufacturer_id = m.id
WHERE (? = '*' OR df.name LIKE '%' || ? || '%' ESCAPE '\\')
  AND (? IS NULL OR m.name = ?)
GROUP BY c.id, c.name, c.manufacturer_id, c.urls_json
HAVING fileCount > 0
ORDER BY c.name ASC
''',
      variables: [Variable(query), Variable(_escapeLikePattern(query)), Variable(manufacturer), Variable(manufacturer)],
      readsFrom: {db.consoles, db.downloadableFiles, db.manufacturers},
    ).get();

    return rows.map((row) {
      return ConsoleWithFileCount(
        id: row.read<String>('id'),
        name: row.read<String>('name'),
        manufacturerId: row.read<String>('manufacturer_id'),
        urlsJson: row.read<String>('urls_json'),
        fileCount: row.read<int>('fileCount'),
        totalSize: row.read<int>('totalSize'),
      );
    }).toList();
  }

  static DownloadableFileWithTags _toFile(QueryRow row) {
    return DownloadableFileWithTags(
      id: row.read<int>('id'),
      name: row.read<String>('name'),
      fileName: row.read<String>('file_name'),
      consoleId: row.read<String>('console_id'),
      downloadUrl: row.read<String>('download_url'),
      fileSize: row.read<int>('file_size'),
      fileExtension: row.read<String>('file_extension'),
      torrentFileIndex: row.readNullable<int>('torrent_file_index'),
      torrentMagnet: row.readNullable<String>('torrent_magnet'),
      tags: row.readNullable<String>('tags'),
    );
  }
}
