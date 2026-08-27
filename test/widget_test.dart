import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pixelvault/core/db/database.dart';
import 'package:pixelvault/core/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pixelvault/app.dart';

void main() {
  setUpAll(() {
    // Avoid google_fonts trying to fetch font files over the network
    // during widget tests (no real internet access in the test sandbox).
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('App boots to the Onboarding screen on first launch', (tester) async {
    // A language has already been chosen so the router lands on onboarding
    // directly instead of the first-run language-select screen.
    SharedPreferences.setMockInitialValues({'locale_code': 'pt'});
    // Uses an in-memory Drift database instead of drift_flutter's
    // platform-channel-backed one, since plain widget tests don't have
    // path_provider wired up.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith((ref) {
            final db = AppDatabase(NativeDatabase.memory());
            ref.onDispose(db.close);
            return db;
          }),
        ],
        child: const PixelVaultApp(),
      ),
    );
    // pumpAndSettle would spin forever while a CircularProgressIndicator is
    // showing (e.g. during the async catalog-seeding FutureProvider), so
    // pump a bounded number of frames instead.
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // On first launch, onboardingCompleted is false so we should see
    // the onboarding screen with PIXELVAULT header and Saltar/Seguinte.
    expect(find.text('PIXELVAULT'), findsOneWidget);
    expect(find.text('Saltar'), findsOneWidget);
    expect(find.text('Seguinte'), findsOneWidget);

    // Dispose the tree ourselves and pump once more so the Drift stream
    // query's teardown timer fires before the test's automatic invariant
    // check (`!timersPending`) runs.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  });
}
