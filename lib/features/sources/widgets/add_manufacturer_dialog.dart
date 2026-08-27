import 'package:flutter/material.dart';

import '../../../core/theme/gengar_components.dart';
import '../../../l10n/app_localizations.dart';

class AddManufacturerDialog extends StatelessWidget {
  const AddManufacturerDialog({
    super.key,
    required this.idController,
    required this.nameController,
    required this.onSubmit,
  });

  final TextEditingController idController;
  final TextEditingController nameController;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.addManufacturerDialogTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: idController,
            decoration: InputDecoration(labelText: l10n.addManufacturerDialogIdLabel),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: nameController,
            decoration: InputDecoration(labelText: l10n.addManufacturerDialogNameLabel),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.commonCancel)),
        GengarPrimaryButton(label: l10n.commonAdd, onPressed: onSubmit),
      ],
    );
  }
}
