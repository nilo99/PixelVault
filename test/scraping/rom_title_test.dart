import 'package:flutter_test/flutter_test.dart';
import 'package:pixelvault/core/scraping/rom_title.dart';

void main() {
  group('title', () {
    test('drops the extension, including an archive around a named disc image', () {
      expect(RomTitle.title('God of War II (USA).chd'), 'God of War II');
      expect(RomTitle.title('God of War II (USA).iso.7z'), 'God of War II');
      expect(RomTitle.title('God of War II (Europe, Australia) (En,Fr,De).7z'), 'God of War II');
    });

    test('drops every (…), […] and {…} tag group', () {
      expect(RomTitle.title('Final Fantasy VII (USA) (Disc 1) [!].chd'), 'Final Fantasy VII');
      expect(RomTitle.title('Metroid {Proto} (USA).nes'), 'Metroid');
    });

    test('repairs names stored by older builds with the extension still attached', () {
      // The scraper used to store `name` as "God of War .chd".
      expect(RomTitle.title('God of War .chd'), 'God of War');
    });

    test('turns underscores into spaces', () {
      expect(RomTitle.title('Crash_Bandicoot_(USA).bin'), 'Crash Bandicoot');
    });

    test('moves a trailing English article back to the front', () {
      expect(
        RomTitle.title('Legend of Zelda, The - Ocarina of Time (USA).z64'),
        'The Legend of Zelda - Ocarina of Time',
      );
      expect(RomTitle.title('Legend of Zelda, The (USA).nes'), 'The Legend of Zelda');
    });

    test('does not move a comma-separated word that is not an article', () {
      expect(RomTitle.title('Hello, A New World (USA).gba'), 'Hello, A New World');
    });

    test('leaves an already clean title alone', () {
      expect(RomTitle.title('Pokemon Y'), 'Pokemon Y');
    });

    test('does not mistake a trailing version number for an extension', () {
      expect(RomTitle.title('Super Mario Bros. 3'), 'Super Mario Bros. 3');
    });
  });

  group('forCatalog', () {
    test('takes the title from the file name, not from truncated link text', () {
      expect(
        RomTitle.forCatalog(
          fileName: 'God of War II (Europe, Australia) (En,Fr,De).7z',
          displayName: 'God of War II (Europe, Au..>',
        ),
        'God of War II',
      );
    });

    test('falls back to the display name when the file name yields nothing', () {
      expect(RomTitle.forCatalog(fileName: '', displayName: 'Ico (USA)'), 'Ico');
    });
  });

  group('key', () {
    test('every region and format of one game shares a key', () {
      final keys = {
        RomTitle.key('God of War (USA).iso'),
        RomTitle.key('God of War (Europe).7z'),
        RomTitle.key('God of War (Japan).chd'),
        RomTitle.key('God of War (USA).iso.7z'),
        RomTitle.key('God of War .chd'),
      };
      expect(keys, hasLength(1));
      expect(keys.single, 'god of war');
    });

    test('sequels stay separate', () {
      expect(RomTitle.key('God of War (USA).iso'), isNot(RomTitle.key('God of War II (USA).iso')));
    });

    test('the discs of one game share a key', () {
      expect(
        RomTitle.key('Final Fantasy VII (USA) (Disc 1).chd'),
        RomTitle.key('Final Fantasy VII (USA) (Disc 2).chd'),
      );
    });

    test('ignores case, accents and punctuation', () {
      expect(RomTitle.key('Pokémon - Emerald Version'), RomTitle.key('pokemon emerald version'));
    });

    test('keeps non-Latin titles distinct instead of collapsing them to nothing', () {
      expect(RomTitle.key('ドラゴンクエスト (Japan).nds'), isNotEmpty);
      expect(RomTitle.key('ドラゴンクエスト (Japan).nds'), isNot(RomTitle.key('ファイナルファンタジー (Japan).nds')));
    });
  });
}
