import 'package:app_links/app_links.dart';

/// Wraps `app_links`' cold-start + live-link streams into a single Stream —
/// covers both "app was already open when the link was tapped" and "the
/// link cold-launched the app". Used for the "Instalar" links a browser
/// opens from the companion sources website (`pixelvault://install?token=`).
class DeepLinkService {
  DeepLinkService([AppLinks? appLinks]) : _appLinks = appLinks ?? AppLinks();

  final AppLinks _appLinks;

  Stream<Uri> get linkStream async* {
    final initial = await _appLinks.getInitialLink();
    if (initial != null) yield initial;
    yield* _appLinks.uriLinkStream;
  }
}
