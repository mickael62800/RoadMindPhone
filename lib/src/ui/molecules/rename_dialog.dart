import 'package:flutter/material.dart';
import 'package:roadmindphone/src/ui/atoms/atoms.dart';

/// A reusable dialog for renaming items (projects, sessions, etc.)
///
/// This molecule combines atoms to create a consistent rename experience
/// across the application.
Future<String?> showRenameDialog({
  required BuildContext context,
  required String title,
  required String hintText,
  String? initialValue,
}) async {
  final controller = TextEditingController(text: initialValue);

  final result = await showDialog<String>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: TitleText(text: title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: hintText),
          onSubmitted: (value) {
            Navigator.of(dialogContext).pop(value);
          },
        ),
        actions: <Widget>[
          ActionButton(
            text: 'ANNULER',
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
          ),
          ActionButton(
            text: 'RENOMMER',
            onPressed: () {
              Navigator.of(dialogContext).pop(controller.text);
            },
          ),
        ],
      );
    },
  );

  // Note: We intentionally don't dispose the controller here.
  // Disposing immediately after showDialog returns can cause issues during
  // dialog close animations. The controller will be garbage collected when
  // no longer referenced, which is safe and acceptable for this use case.

  return result;
}
