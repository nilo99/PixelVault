import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.aboutTitle)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('PixelVault', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              l10n.aboutBody,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
