import 'package:flutter_test/flutter_test.dart';
import 'package:pixelvault/core/scraping/file_parsing.dart';

void main() {
  test('extractNameAndTags cleans name and extracts recognizable tags', () {
    final (name, tags) =
        FileParsing.extractNameAndTags('Burnout Paradise (En,Es,Fr) (NTSC)');
    expect(name, 'Burnout Paradise');
    expect(tags, containsAll(['EN', 'ES', 'FR', 'NTSC']));
  });

  test('extractNameAndTags discards noise tokens', () {
    final (name, tags) = FileParsing.extractNameAndTags('Some Game (Not A Tag Group)');
    expect(name, 'Some Game');
    expect(tags, isEmpty);
  });

  test('buildDownloadUrl resolves relative hrefs against the base', () {
    final url = FileParsing.buildDownloadUrl(
      'https://example.com/roms/gba/',
      'Pokemon%20Emerald.zip',
    );
    expect(url, 'https://example.com/roms/gba/Pokemon%20Emerald.zip');
  });

  test('buildDownloadUrl keeps absolute hrefs as-is', () {
    final url = FileParsing.buildDownloadUrl(
      'https://example.com/roms/',
      'https://cdn.example.com/file.zip',
    );
    expect(url, 'https://cdn.example.com/file.zip');
  });

  test('optimizeMagnetUri trims trackers beyond the max', () {
    final trackers = List.generate(10, (i) => 'tr=udp%3A%2F%2Ftracker$i.example%3A80').join('&');
    final uri = 'magnet:?xt=urn:btih:abc123&dn=Test&$trackers';

    final optimized = FileParsing.optimizeMagnetUri(uri);

    expect(optimized.split('tr=').length - 1, 4);
    expect(optimized, startsWith('magnet:?xt=urn:btih:abc123'));
  });

  test('optimizeMagnetUri leaves short tracker lists untouched', () {
    const uri = 'magnet:?xt=urn:btih:abc123&dn=Test&tr=udp%3A%2F%2Fa';
    expect(FileParsing.optimizeMagnetUri(uri), uri);
  });
}
