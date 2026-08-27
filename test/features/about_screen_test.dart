import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixelvault/features/about/about_screen.dart';
import 'package:pixelvault/l10n/app_localizations.dart';

void main() {
  testWidgets('renders the title and body text', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('pt'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AboutScreen(),
      ),
    );
    await tester.pump();

    expect(find.text('Sobre'), findsOneWidget);
    expect(find.text('PixelVault'), findsOneWidget);
    expect(find.text('App pessoal de biblioteca e downloads de ROMs.'), findsOneWidget);
  });
}
