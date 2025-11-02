
import 'package:flutter/material.dart';
import 'package:roadmindphone/src/ui/atoms/atoms.dart';

Future<bool?> showConfirmationDialog({
  required BuildContext context,
  required String title,
  required String content,
  String confirmText = 'CONFIRMER',
  String cancelText = 'ANNULER',
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: TitleText(text: title),
        content: BodyText(text: content),
        actions: <Widget>[
          ActionButton(
            onPressed: () => Navigator.of(context).pop(false),
            text: cancelText,
          ),
          ActionButton(
            onPressed: () => Navigator.of(context).pop(true),
            text: confirmText,
          ),
        ],
      );
    },
  );
}
