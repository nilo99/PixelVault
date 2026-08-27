import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:pixelvault/core/models/content_type.dart';
import 'package:pixelvault/core/scraping/http_directory_scraper.dart';

void main() {
  test('parses a directory listing using td.link/td.size classes', () {
    const html = '''
      <html><body><table>
        <tr><td class="link"><a href="../">Parent directory/</a></td><td class="size">-</td></tr>
        <tr><td class="link"><a href="subfolder/">subfolder/</a></td><td class="size">-</td></tr>
        <tr><td class="link"><a href="Burnout%20Paradise%20(En%2CEs%2CFr)%20(NTSC).zip" title="Burnout Paradise (En,Es,Fr) (NTSC).zip">Burnout Paradise (En,Es,Fr) (NTSC).zip</a></td><td class="size">1.4GB</td></tr>
      </table></body></html>
    ''';
    final doc = html_parser.parse(html);

    final (companions, tags) = HttpDirectoryScraper.parseListing(
      doc: doc,
      baseUrl: 'https://example.com/roms/gc/',
      consoleId: 'nintendo_gamecube',
      contentType: ContentType.game,
    );

    expect(companions, hasLength(1));
    // extractNameAndTags only strips `(...)` groups, not the trailing
    // extension — this matches Milou's DatabaseScrapingService verbatim.
    expect(companions.single.name.value, 'Burnout Paradise .zip');
    expect(companions.single.consoleId.value, 'nintendo_gamecube');
    expect(companions.single.fileExtension.value, '.zip');
    expect(companions.single.fileSize.value, 1400000000);
    // "GAME" is > 3 chars so normalizeTag title-cases it, same as Milou.
    expect(tags.single, containsAll(['EN', 'ES', 'FR', 'NTSC', 'Game']));
  });

  test('falls back to first <a> and second <td> when no link/size classes are present', () {
    const html = '''
      <html><body><table>
        <tr><td><a href="..">..</a></td></tr>
        <tr><td><a href="Sonic%20Adventure%202%20(USA).zip">Sonic Adventure 2 (USA).zip</a></td><td>750MB</td></tr>
      </table></body></html>
    ''';
    final doc = html_parser.parse(html);

    final (companions, tags) = HttpDirectoryScraper.parseListing(
      doc: doc,
      baseUrl: 'https://example.com/roms/gc',
      consoleId: 'nintendo_gamecube',
    );

    expect(companions, hasLength(1));
    expect(companions.single.name.value, 'Sonic Adventure 2 .zip');
    expect(companions.single.downloadUrl.value,
        'https://example.com/roms/gc/Sonic%20Adventure%202%20(USA).zip');
    expect(companions.single.fileSize.value, 750000000);
    expect(tags.single, containsAll(['USA', 'Game']));
  });

  test('throws when the page has no table (e.g. source is down)', () {
    final doc = html_parser.parse('<html><body><p>Service unavailable</p></body></html>');

    expect(
      () => HttpDirectoryScraper.parseListing(
        doc: doc,
        baseUrl: 'https://example.com/roms/gc/',
        consoleId: 'nintendo_gamecube',
      ),
      throwsStateError,
    );
  });
}
