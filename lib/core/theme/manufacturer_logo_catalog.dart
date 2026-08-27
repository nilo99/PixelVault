/// Maps manufacturer DB IDs to their corresponding logo asset paths.
/// Only the three built-in manufacturers have pre-bundled logos —
/// user-added manufacturers fall back to the styled wordmark text.
abstract final class ManufacturerLogoCatalog {
  static const Map<String, String> assets = {
    'nintendo': 'assets/manufacturers/nintendo.png',
    'sony': 'assets/manufacturers/sony.png',
    'sega': 'assets/manufacturers/sega.png',
  };
}
