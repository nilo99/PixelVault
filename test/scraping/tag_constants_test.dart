import 'package:flutter_test/flutter_test.dart';
import 'package:pixelvault/core/scraping/tag_constants.dart';

void main() {
  test('categorizes region, language, video-standard and content-type tags', () {
    final result = TagCategorizer.categorize(['USA', 'EN', 'NTSC', 'DEMO', 'JAPAN']);

    expect(result.regions.tags, containsAll(['USA', 'JAPAN']));
    expect(result.languages.tags, contains('EN'));
    expect(result.videoStandards.tags, ['NTSC']);
    expect(result.contentTypes.tags, ['DEMO']);
  });

  test('continents are folded into the regions bucket', () {
    final result = TagCategorizer.categorize(['EUROPE', 'ASIA']);
    expect(result.regions.tags, containsAll(['EUROPE', 'ASIA']));
  });

  test('recognizes 2-3 letter codes as languages regardless of case', () {
    final result = TagCategorizer.categorize(['fr', 'ES', 'ptb']);
    expect(result.languages.tags, containsAll(['fr', 'ES', 'ptb']));
  });

  test('recognizes file-extension-shaped tags', () {
    final result = TagCategorizer.categorize(['.ZIP', '.7Z']);
    expect(result.fileTypes.tags, containsAll(['.ZIP', '.7Z']));
  });

  test('unrecognized tags are dropped from every bucket', () {
    final result = TagCategorizer.categorize(['RandomNoiseTagThatMeansNothing']);
    expect(result.regions.tags, isEmpty);
    expect(result.languages.tags, isEmpty);
    expect(result.videoStandards.tags, isEmpty);
    expect(result.contentTypes.tags, isEmpty);
    expect(result.fileTypes.tags, isEmpty);
  });

  test('each bucket is sorted alphabetically', () {
    final result = TagCategorizer.categorize(['USA', 'CANADA', 'BRAZIL']);
    expect(result.regions.tags, ['BRAZIL', 'CANADA', 'USA']);
  });

  test('a tag is only ever placed in one bucket (region checked before language)', () {
    // "UK" matches the region set but would also match the 2-3 letter
    // language-code pattern; region classification must win.
    final result = TagCategorizer.categorize(['UK']);
    expect(result.regions.tags, ['UK']);
    expect(result.languages.tags, isEmpty);
  });
}
