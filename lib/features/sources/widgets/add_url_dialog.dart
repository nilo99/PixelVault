import 'package:flutter/material.dart';

import '../../../core/db/database.dart';
import '../../../core/models/content_type.dart';
import '../../../core/theme/gengar_components.dart';
import '../../../l10n/app_localizations.dart';

/// Add-source dialog — a single URL/magnet can be attached to more than one
/// console at once (e.g. a combo pack torrent), so this shows a checklist of
/// every known console instead of being locked to whichever row it was
/// opened from.
class AddUrlDialog extends StatelessWidget {
  const AddUrlDialog({
    super.key,
    required this.urlController,
    required this.contentType,
    required this.onContentTypeChanged,
    required this.allConsoles,
    required this.selectedConsoleIds,
    required this.onToggleConsole,
    required this.onSubmit,
  });

  final TextEditingController urlController;
  final ContentType contentType;
  final ValueChanged<ContentType> onContentTypeChanged;
  final List<Console> allConsoles;
  final Set<String> selectedConsoleIds;
  final ValueChanged<String> onToggleConsole;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.addUrlDialogTitle),
      content: SizedBox(
        width: 400,
        // The dialog's max height shrinks when the keyboard is visible; with
        // a full console checklist the fixed-height content can exceed that
        // and overflow underneath the action buttons (tappable-but-invisible
        // overlap). Scrolling the whole body avoids that regardless of
        // keyboard state or console count.
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                key: const Key('add_url_dialog_url_field'),
                controller: urlController,
                decoration: InputDecoration(
                  labelText: l10n.addUrlDialogUrlLabel,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ContentType>(
                initialValue: contentType,
                decoration: InputDecoration(labelText: l10n.addUrlDialogContentTypeLabel),
                items: ContentType.values
                    .map((type) => DropdownMenuItem(value: type, child: Text(type.toJson())))
                    .toList(),
                onChanged: (value) {
                  if (value != null) onContentTypeChanged(value);
                },
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.addUrlDialogApplyTo(selectedConsoleIds.length),
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
              SizedBox(
                height: 220,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: allConsoles.length,
                  itemBuilder: (context, index) {
                    final console = allConsoles[index];
                    return CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(console.name),
                      value: selectedConsoleIds.contains(console.id),
                      onChanged: (_) => onToggleConsole(console.id),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.commonCancel)),
        GengarPrimaryButton(
          key: const Key('add_url_dialog_submit_button'),
          label: l10n.addUrlDialogSubmitButton,
          onPressed: onSubmit,
        ),
      ],
    );
  }
}
