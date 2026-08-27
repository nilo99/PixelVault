# pixelvault

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Local development — deep-link HMAC secret

`lib/core/deeplink/source_install_client.dart` HMAC-signs every request that
resolves a `pixelvault://install?token=...` deep link against the companion
website's `/api/resolve` endpoint. The shared secret is passed in at build
time via `--dart-define=PIXELVAULT_HMAC_SECRET=<value>` (or, more
conveniently, `--dart-define-from-file`) — it is never committed to the repo.

- **Default** (`flutter run`, `flutter build apk --debug`/`--profile`): no
  setup needed. A placeholder secret is used automatically, the app opens
  normally, and any real "Instalar" tap fails with a friendly "link já não é
  válido" message (the server rejects the placeholder) rather than crashing.
- **To resolve real deep links locally**: copy `secrets.example.json` to
  `secrets.json` (git-ignored), fill in the real value (the same one
  configured as the `PIXELVAULT_HMAC_SECRET` env var on the companion site's
  Vercel deployment), and run with
  `flutter run --dart-define-from-file=secrets.json`.
- **Release builds** (`flutter build apk --release`/`appbundle`) **must**
  pass the real secret via `--dart-define-from-file=secrets.json` (or CI
  secret injection) — omitting it throws a clear `StateError` at startup
  instead of silently shipping a broken or insecure build.
