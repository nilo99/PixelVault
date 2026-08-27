import '../db/database.dart';
import '../security/urls_cipher_holder.dart';
import 'url_entry.dart';

/// Decodes the `urlsJson` column on the Drift-generated [Console] row into
/// typed [UrlEntry] objects — encrypted at rest via [UrlsCipherHolder], see
/// its doc comment for the migration story from older plaintext rows.
extension ConsoleUrls on Console {
  List<UrlEntry> get urls => UrlsCipherHolder.instance.decode(urlsJson);
}
