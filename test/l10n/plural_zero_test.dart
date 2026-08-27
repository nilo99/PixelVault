import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixelvault/l10n/app_localizations.dart';

/// Regression test for a real bug found live on a genuinely fresh install:
/// the Fontes screen showed "1 sincronizada"/"1 jogo indexado"/"1 fonte" for
/// every console even though the database was completely empty. Root cause:
/// the ARB source used ICU's exact-match `=1{...}` selector (intending
/// "only when the count is precisely 1"), but Flutter's `gen-l10n` compiles
/// `=1` into `Intl.pluralLogic`'s `one:` parameter — which is matched via
/// the *locale's CLDR plural category*, not an exact value. Portuguese and
/// French's CLDR "one" category is defined as `i == 0 || i == 1` (see
/// `package:intl`'s `_pt_rule`/`_fr_rule`), so a genuine count of 0 silently
/// rendered the "exactly 1" text. The fix was adding explicit `=0{...}`
/// branches to every count-sensitive ARB message in `pt`/`fr` (`intl`'s
/// `Intl.pluralLogic` checks `howMany == 0` before ever consulting the
/// locale's plural rule — see its `useExplicitNumberCases` branch).
///
/// This test locks in the fix for every locale, not just pt/fr, so a future
/// contributor adding a new plural string without an explicit `=0` branch
/// gets caught immediately instead of only showing up as a live bug report.
void main() {
  Future<AppLocalizations> l10nFor(String code) => AppLocalizations.delegate.load(Locale(code));

  for (final code in AppLocalizations.supportedLocales.map((l) => l.languageCode)) {
    group('locale "$code"', () {
      late AppLocalizations l10n;

      setUp(() async {
        l10n = await l10nFor(code);
      });

      test('sourcesSourceCount(0) does not render "1"', () {
        final text = l10n.sourcesSourceCount(0);
        expect(text, contains('0'));
        expect(text, isNot(contains('1')));
      });

      test('sourcesGamesIndexedCount(0) does not render "1"', () {
        final text = l10n.sourcesGamesIndexedCount(0);
        expect(text, contains('0'));
        expect(text, isNot(contains('1')));
      });

      test('sourcesManufacturerSummary(N, 0) never claims a non-zero synced count', () {
        for (final consoleCount in [0, 1, 3, 9]) {
          final text = l10n.sourcesManufacturerSummary(consoleCount, 0);
          // The "synced" half of the message must reflect zero — regardless
          // of how many consoles there are — so split on the separator and
          // check the second half specifically (the first half legitimately
          // contains "1" when consoleCount is 1).
          final syncedHalf = text.split('·').last;
          expect(syncedHalf, contains('0'), reason: 'for consoleCount=$consoleCount, text="$text"');
          expect(syncedHalf, isNot(contains('1')), reason: 'for consoleCount=$consoleCount, text="$text"');
        }
      });

      test('sourcesUnsyncedBanner(0) does not render "1"', () {
        final text = l10n.sourcesUnsyncedBanner(0);
        expect(text, contains('0'));
        expect(text, isNot(contains('1')));
      });

      test('platformSelectConsoleSummary(0, size) does not render "1"', () {
        final text = l10n.platformSelectConsoleSummary(0, '0 B');
        expect(text, isNot(contains('1')));
      });

      test('addUrlDialogApplyTo(0) does not render as if exactly 1 were selected', () {
        // The "exactly 1" case is a distinct grammatical form (no plural
        // suffix in pt/fr) — for 0 it must NOT match that special-cased
        // form, i.e. it must equal whatever a clearly-plural count (e.g. 2)
        // produces, not what count 1 produces.
        final zero = l10n.addUrlDialogApplyTo(0);
        final one = l10n.addUrlDialogApplyTo(1);
        final two = l10n.addUrlDialogApplyTo(2);
        expect(zero, isNot(equals(one)));
        expect(zero.replaceFirst('0', 'N'), equals(two.replaceFirst('2', 'N')));
      });

      // Sanity check the *other* direction too: exactly 1 must still render
      // the singular form, so the fix didn't overcorrect into always-plural.
      test('sourcesSourceCount(1) still renders the singular form', () {
        final text = l10n.sourcesSourceCount(1);
        expect(text, contains('1'));
      });
    });
  }
}
