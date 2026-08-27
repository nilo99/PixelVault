/// Port of Milou's `FileSizeUtils.parseFileSize` — parses human-readable
/// sizes ("512 MB", "1.2 GiB") from directory-listing pages into bytes.
abstract final class FileSizeUtils {
  static const _kilobyte = 1000;
  static const _kibibyte = 1024;
  static const _megabyte = 1000 * 1000;
  static const _mebibyte = 1024 * 1024;
  static const _gigabyte = 1000 * 1000 * 1000;
  static const _gibibyte = 1024 * 1024 * 1024;
  static const _terabyte = 1000 * 1000 * 1000 * 1000;
  static const _tebibyte = 1024 * 1024 * 1024 * 1024;

  static final _pattern = RegExp(
    r'(\d+(?:\.\d+)?)\s*([KMGTPE]?i?B)',
    caseSensitive: false,
  );

  static int parseFileSize(String sizeString) {
    if (sizeString.trim().isEmpty || sizeString == '0') return 0;

    final clean = sizeString.trim().replaceAll(',', '');
    final match = _pattern.firstMatch(clean);
    if (match == null) return 0;

    final number = double.tryParse(match.group(1)!);
    if (number == null) return 0;
    final unit = match.group(2)!.toUpperCase();

    final multiplier = switch (unit) {
      'B' => 1,
      'KB' => _kilobyte,
      'KIB' => _kibibyte,
      'MB' => _megabyte,
      'MIB' => _mebibyte,
      'GB' => _gigabyte,
      'GIB' => _gibibyte,
      'TB' => _terabyte,
      'TIB' => _tebibyte,
      'PB' => _terabyte * _kilobyte,
      'PIB' => _tebibyte * _kibibyte,
      'EB' => _terabyte * _megabyte,
      'EIB' => _tebibyte * _mebibyte,
      _ => 0,
    };
    return (number * multiplier).toInt();
  }
}
