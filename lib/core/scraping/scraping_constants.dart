/// Port of Milou's `ScrapingConstants` + `TorrentConstants` (the subset
/// relevant to pure-Dart scraping; torrent-session constants live in the
/// native plugin).
abstract final class ScrapingConstants {
  static const connectionTimeoutMs = 30000;
  static const maxRetries = 3;
  static const retryDelayMs = 2000;
  static const requestDelayMs = 1000;
  static const userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36';

  static const tableSelector = 'table';
  static const parentDirectory = '..';
  static const currentDirectory = '.';
  static const unknownFileSize = '?';
  static const defaultFileSize = '0B';
}

abstract final class TorrentConstants {
  static const maxTrackersPerMagnet = 4;
}
