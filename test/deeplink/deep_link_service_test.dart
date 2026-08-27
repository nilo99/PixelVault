import 'package:app_links/app_links.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pixelvault/core/deeplink/deep_link_service.dart';

class _MockAppLinks extends Mock implements AppLinks {}

void main() {
  test('yields the cold-start link first, then live links', () async {
    final appLinks = _MockAppLinks();
    final coldStart = Uri.parse('pixelvault://install?token=cold-start');
    final live = Uri.parse('pixelvault://install?token=live-link');
    when(() => appLinks.getInitialLink()).thenAnswer((_) async => coldStart);
    when(() => appLinks.uriLinkStream).thenAnswer((_) => Stream.value(live));

    final links = await DeepLinkService(appLinks).linkStream.toList();

    expect(links, [coldStart, live]);
  });

  test('yields only live links when there is no cold-start link', () async {
    final appLinks = _MockAppLinks();
    final live = Uri.parse('pixelvault://install?token=live-link');
    when(() => appLinks.getInitialLink()).thenAnswer((_) async => null);
    when(() => appLinks.uriLinkStream).thenAnswer((_) => Stream.value(live));

    final links = await DeepLinkService(appLinks).linkStream.toList();

    expect(links, [live]);
  });
}
