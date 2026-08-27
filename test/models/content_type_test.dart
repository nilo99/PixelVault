import 'package:flutter_test/flutter_test.dart';
import 'package:pixelvault/core/models/content_type.dart';

void main() {
  group('ContentType.fromJson', () {
    test('parses known values case-insensitively', () {
      expect(ContentType.fromJson('GAME'), ContentType.game);
      expect(ContentType.fromJson('game'), ContentType.game);
      expect(ContentType.fromJson('Game'), ContentType.game);
      expect(ContentType.fromJson('MISCELLANEOUS'), ContentType.miscellaneous);
      expect(ContentType.fromJson('miscellaneous'), ContentType.miscellaneous);
      expect(ContentType.fromJson('RETROACHIEVEMENTS'), ContentType.retroachievements);
      expect(ContentType.fromJson('retroachievements'), ContentType.retroachievements);
    });

    test('defaults to game for unknown values', () {
      expect(ContentType.fromJson('unknown'), ContentType.game);
      expect(ContentType.fromJson(''), ContentType.game);
      expect(ContentType.fromJson('SOMETHING'), ContentType.game);
    });
  });

  group('ContentType.toJson', () {
    test('serializes all values to uppercase strings', () {
      expect(ContentType.game.toJson(), 'GAME');
      expect(ContentType.miscellaneous.toJson(), 'MISCELLANEOUS');
      expect(ContentType.retroachievements.toJson(), 'RETROACHIEVEMENTS');
    });

    test('round-trips through fromJson/toJson', () {
      for (final ct in ContentType.values) {
        expect(ContentType.fromJson(ct.toJson()), ct);
      }
    });
  });
}
