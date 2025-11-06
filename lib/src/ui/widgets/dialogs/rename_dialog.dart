import 'package:flutter/material.dart';

class RenameDialog extends StatelessWidget {
  final String title;
  final String hintText;
  final String initialValue;

  const RenameDialog({
    super.key,
    required this.title,
    required this.hintText,
    required this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(text: initialValue);
    return AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        decoration: InputDecoration(hintText: hintText),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(controller.text),
          child: const Text('Renommer'),
        ),
      ],
    );
  }
}
