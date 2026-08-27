import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixelvault/core/db/database.dart';
import 'package:pixelvault/core/providers.dart';
import 'package:pixelvault/core/settings/settings_repository.dart';
import 'package:pixelvault/core/theme/components/gengar_gradient_toggle.dart';
import 'package:pixelvault/features/settings/settings_screen.dart';
import 'package:pixelvault/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<ProviderContainer> pumpScreen(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer(
      overrides: [
        allConsolesProvider.overrideWith((ref) => Stream.value(const <Console>[])),
      ],
    );
    addTearDown(container.dispose);
    await container.read(settingsProvider.future);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('pt'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SettingsScreen(),
        ),
      ),
    );
    await tester.pump();
    return container;
  }

  /// The Key sits on the whole row (title + toggle); its center often lands
  /// on the title text rather than the actual switch, so target the switch
  /// widget itself. The row itself may not be built yet (lazy ListView), so
  /// scroll to the row by key first, then to the switch within it.
  Future<void> tapToggleIn(WidgetTester tester, Key rowKey) async {
    final row = find.byKey(rowKey);
    // Sliver-backed ListView only mounts children near the viewport, so the
    // row may not exist in the tree at all until scrolled close enough for
    // it to enter the cache extent.
    await tester.scrollUntilVisible(row, 200, maxScrolls: 100);
    final toggle = find.descendant(of: row, matching: find.byType(GengarGradientToggle));
    // scrollUntilVisible only checks that the finder exists (i.e. is
    // mounted), not that it's actually within the viewport bounds, so do a
    // real ensureVisible pass to bring it fully on-screen before tapping.
    await tester.ensureVisible(toggle);
    await tester.pumpAndSettle();
    await tester.tap(toggle);
  }

  testWidgets('renders the settings sections', (tester) async {
    await pumpScreen(tester);
    expect(find.text('Definições'), findsOneWidget);
    expect(find.text('Separar por consola'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Extração automática'), 200);
    expect(find.text('Extração automática'), findsOneWidget);
  });

  testWidgets('toggling "Separar por consola" persists the new value', (tester) async {
    final container = await pumpScreen(tester);
    expect(container.read(settingsProvider).value?.separateByConsole, isFalse);

    await tapToggleIn(tester, const Key('settings_separate_by_console_toggle'));
    await tester.pump();

    expect(container.read(settingsProvider).value?.separateByConsole, isTrue);
  });

  testWidgets('toggling "Extração automática" persists the new value', (tester) async {
    final container = await pumpScreen(tester);
    expect(container.read(settingsProvider).value?.autoUnzip, isTrue);

    await tapToggleIn(tester, const Key('settings_auto_unzip_toggle'));
    await tester.pump();

    expect(container.read(settingsProvider).value?.autoUnzip, isFalse);
  });
}
