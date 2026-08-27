import 'package:flutter_test/flutter_test.dart';
import 'package:pixelvault/core/scraping/file_size_utils.dart';

void main() {
  test('parses decimal units (base 1000)', () {
    expect(FileSizeUtils.parseFileSize('1 KB'), 1000);
    expect(FileSizeUtils.parseFileSize('1 MB'), 1000000);
    expect(FileSizeUtils.parseFileSize('1 GB'), 1000000000);
    expect(FileSizeUtils.parseFileSize('1 TB'), 1000000000000);
  });

  test('parses binary units (base 1024)', () {
    expect(FileSizeUtils.parseFileSize('1 KiB'), 1024);
    expect(FileSizeUtils.parseFileSize('1 MiB'), 1024 * 1024);
    expect(FileSizeUtils.parseFileSize('1 GiB'), 1024 * 1024 * 1024);
    expect(FileSizeUtils.parseFileSize('1.4GB'), 1400000000);
  });

  test('is case-insensitive and tolerates no space before the unit', () {
    expect(FileSizeUtils.parseFileSize('512mb'), 512000000);
    expect(FileSizeUtils.parseFileSize('2.5Gib'), (2.5 * 1024 * 1024 * 1024).toInt());
  });

  test('strips thousands-separator commas before parsing', () {
    expect(FileSizeUtils.parseFileSize('1,024 B'), 1024);
  });

  test('returns 0 for empty, zero, or unparsable input', () {
    expect(FileSizeUtils.parseFileSize(''), 0);
    expect(FileSizeUtils.parseFileSize('   '), 0);
    expect(FileSizeUtils.parseFileSize('0'), 0);
    expect(FileSizeUtils.parseFileSize('-'), 0);
    expect(FileSizeUtils.parseFileSize('unknown'), 0);
  });

  test('plain bytes have no multiplier', () {
    expect(FileSizeUtils.parseFileSize('500 B'), 500);
  });
}
