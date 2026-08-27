import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../models/content_type.dart';
import '../../models/url_entry.dart';
import '../../scraping/file_parsing.dart';
import '../daos/catalog_repository.dart';
import '../database.dart';

/// Port of Milou's `DefaultSourcesLoader` — reads the bundled
/// `assets/consoles.json` (unchanged from the original app) and seeds
/// Manufacturers/Consoles, replacing any existing catalog. Console/manufacturer
/// display names are derived from the JSON keys with the same special-casing
/// (SNES, PSx, N64, GB/GBC/GBA) as the original app.
class ConsolesSeedLoader {
  ConsolesSeedLoader(this.catalog);

  final CatalogRepository catalog;

  static const _acronyms = {'snes', 'ps1', 'ps2', 'ps3', 'ps4', 'ps5', 'n64', 'gb', 'gbc', 'gba'};

  Future<void> loadDefaultSources() async {
    await catalog.clearAll();

    final jsonString = await rootBundle.loadString('assets/consoles.json');
    final root = jsonDecode(jsonString) as Map<String, dynamic>;

    final manufacturerRows = <ManufacturersCompanion>[];
    final consoleRows = <ConsolesCompanion>[];

    for (final manufacturerEntry in root.entries) {
      final manufacturerId = manufacturerEntry.key;
      final consolesJson = manufacturerEntry.value as Map<String, dynamic>;

      manufacturerRows.add(ManufacturersCompanion.insert(
        id: manufacturerId,
        name: _formatWords(manufacturerId),
      ));

      for (final consoleEntry in consolesJson.entries) {
        final consoleKey = consoleEntry.key;
        final consoleJson = consoleEntry.value as Map<String, dynamic>;
        final urlsJson = consoleJson['urls'] as List<dynamic>;

        final entries = urlsJson.map((raw) {
          final map = raw as Map<String, dynamic>;
          var url = map['url'] as String;
          if (url.startsWith('magnet:')) {
            url = FileParsing.optimizeMagnetUri(url);
          }
          return UrlEntry(
            url: url,
            contentType: map['contentType'] == null
                ? ContentType.game
                : ContentType.fromJson(map['contentType'] as String),
            folders: (map['folders'] as List?)?.cast<String>(),
          );
        }).toList();

        consoleRows.add(ConsolesCompanion.insert(
          id: '${manufacturerId}_$consoleKey',
          name: _formatConsoleName(consoleKey),
          manufacturerId: manufacturerId,
          urlsJson: jsonEncode(entries.map((e) => e.toJson()).toList()),
        ));
      }
    }

    await catalog.insertManufacturers(manufacturerRows);
    await catalog.insertConsoles(consoleRows);
  }

  static String _formatWords(String name) {
    return name.split('_').map(_capitalize).join(' ');
  }

  static String _formatConsoleName(String name) {
    return name.split('_').map((word) {
      final lower = word.toLowerCase();
      if (_acronyms.contains(lower)) return word.toUpperCase();
      return _capitalize(word);
    }).join(' ');
  }

  static String _capitalize(String word) {
    if (word.isEmpty) return word;
    return word[0].toUpperCase() + word.substring(1);
  }
}
