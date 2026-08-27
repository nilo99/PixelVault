import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pixelvault/core/settings/settings_repository.dart';
import 'package:pixelvault/features/language_select/language_select_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<ProviderContainer> pumpScreen(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(settingsProvider.future);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: LanguageSelectScreen()),
      ),
    );
    await tester.pump();
    return container;
  }

  testWidgets('renders all 5 supported languages, each in its own name', (tester) async {
    await pumpScreen(tester);

    for (final locale in kSupportedLocales) {
      expect(find.byKey(Key('language_select_option_${locale.code}')), findsOneWidget);
      expect(find.text(locale.ownName), findsOneWidget);
    }
  });

  testWidgets('tapping a language sets it as the chosen locale', (tester) async {
    final container = await pumpScreen(tester);
    expect(container.read(settingsProvider).value?.localeCode, isNull);

    final option = find.byKey(const Key('language_select_option_de'));
    await tester.ensureVisible(option);
    await tester.pumpAndSettle();
    await tester.tap(option);
    await tester.pump();

    expect(container.read(settingsProvider).value?.localeCode, 'de');
  });

  testWidgets('tapping a different language later overwrites the previous choice', (tester) async {
    final container = await pumpScreen(tester);

    final enOption = find.byKey(const Key('language_select_option_en'));
    await tester.ensureVisible(enOption);
    await tester.pumpAndSettle();
    await tester.tap(enOption);
    await tester.pump();
    expect(container.read(settingsProvider).value?.localeCode, 'en');

    final frOption = find.byKey(const Key('language_select_option_fr'));
    await tester.ensureVisible(frOption);
    await tester.pumpAndSettle();
    await tester.tap(frOption);
    await tester.pump();
    expect(container.read(settingsProvider).value?.localeCode, 'fr');
  });
}
