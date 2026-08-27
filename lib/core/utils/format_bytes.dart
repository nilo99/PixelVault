/// Formats a byte count as a short human-readable string (e.g. "18.4 GB"),
/// shared by the Library rom tiles and the Platform Select console rows.
String formatBytes(int bytes) {
  if (bytes <= 0) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var value = bytes.toDouble();
  var unitIndex = 0;
  while (value >= 1024 && unitIndex < units.length - 1) {
    value /= 1024;
    unitIndex++;
  }
  return '${value.toStringAsFixed(value < 10 ? 1 : 0)} ${units[unitIndex]}';
}
