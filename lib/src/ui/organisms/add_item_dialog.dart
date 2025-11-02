
import 'package:flutter/material.dart';
import 'package:roadmindphone/src/ui/atoms/atoms.dart';
import 'package:roadmindphone/src/ui/molecules/molecules.dart';

Future<String?> showAddItemDialog({
  required BuildContext context,
  required String title,
  required String hintText,
  String confirmText = 'AJOUTER',
  String cancelText = 'ANNULER',
}) {
  final TextEditingController controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: TitleText(text: title),
        content: SettingsTextField(
          controller: controller,
          labelText: hintText,
        ),
        actions: <Widget>[
          ActionButton(
            onPressed: () => Navigator.of(context).pop(),
            text: cancelText,
          ),
          ActionButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                Navigator.of(context).pop(controller.text);
              } else {
                Navigator.of(context).pop();
              }
            },
            text: confirmText,
          ),
        ],
      );
    },
  );
}
