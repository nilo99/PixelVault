import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pixelvault/app.dart';
import 'package:pixelvault/core/db/database.dart';
import 'package:pixelvault/core/providers.dart';
import 'package:pixelvault/core/router/scaffold_with_nav_bar.dart';
import 'package:pixelvault/core/security/urls_cipher_holder.dart';
import 'package:pixelvault/features/library/library_screen.dart';
import 'package:pixelvault/features/platform_select/platform_select_screen.dart';
import 'package:pixelvault/features/settings/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Android Back — the B button on handhelds such as the AYN Thor — used to
/// fall through to `SystemNavigator.pop()` on every tab, which destroyed the
/// activity and every download running in its Flutter engine while the
/// foreground service kept the process alive. These pin down the new
/// behaviour: Back on a secondary tab returns to Plataformas, a pushed page
/// still pops normally, and only Back on Plataformas is handed to the
/// platform (where `MainActivity.popSystemNavigator` backgrounds the app
/// instead of finishing it).
void main() {
  setUpAll(() => UrlsCipherHolder.initForTest());

  late List<String> platformCalls;

  Future<void> pumpFrames(WidgetTester tester, [int count = 30]) async {
    for (var i = 0; i < count; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> bootApp(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'locale_code': 'pt',
      'onboarding_completed': true,
      'esde_prompt_answered': true,
    });
    final db = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        ensureCatalogSeededProvider.overrideWith((ref) async {}),
      ],
    );
    addTearDown(container.dispose);

    platformCalls = [];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        platformCalls.add(call.method);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const PixelVaultApp()),
    );
    await pumpFrames(tester);
  }

  /// Delivers exactly the message Android sends when Back is pressed.
  Future<void> pressBack(WidgetTester tester) async {
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/navigation',
      const JSONMethodCodec().encodeMethodCall(const MethodCall('popRoute')),
      (_) {},
    );
    await pumpFrames(tester, 10);
  }

  void goTo(WidgetTester tester, String location) {
    GoRouter.of(tester.element(find.byType(ScaffoldWithGengarNavBar))).go(location);
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('Back on a secondary tab returns to Plataformas instead of leaving the app', (tester) async {
    await bootApp(tester);
    goTo(tester, '/settings');
    await pumpFrames(tester, 10);
    expect(find.byType(SettingsScreen), findsOneWidget);

    await pressBack(tester);

    expect(find.byType(PlatformSelectScreen), findsOneWidget);
    expect(find.byType(SettingsScreen), findsNothing);
    expect(platformCalls, isNot(contains('SystemNavigator.pop')));
    await unmount(tester);
  });

  testWidgets('Back from a pushed Library page pops the page, not the app', (tester) async {
    await bootApp(tester);
    goTo(tester, '/platforms/library');
    await pumpFrames(tester, 10);
    expect(find.byType(LibraryScreen), findsOneWidget);

    await pressBack(tester);

    expect(find.byType(LibraryScreen), findsNothing);
    expect(find.byType(PlatformSelectScreen), findsOneWidget);
    expect(platformCalls, isNot(contains('SystemNavigator.pop')));
    await unmount(tester);
  });

  testWidgets('Back on Plataformas is handed to the platform, which backgrounds the app', (tester) async {
    await bootApp(tester);
    expect(find.byType(PlatformSelectScreen), findsOneWidget);

    await pressBack(tester);

    expect(platformCalls, contains('SystemNavigator.pop'));
    await unmount(tester);
  });
}
