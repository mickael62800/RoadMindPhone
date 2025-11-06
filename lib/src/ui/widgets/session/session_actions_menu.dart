import 'package:flutter/material.dart';

class SessionActionsMenu extends StatelessWidget {
  final void Function(String) onSelected;
  const SessionActionsMenu({super.key, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onSelected,
      itemBuilder: (BuildContext context) {
        return {'Editer', 'Supprimer', 'Refaire', 'Exporter'}.map((
          String choice,
        ) {
          return PopupMenuItem<String>(value: choice, child: Text(choice));
        }).toList();
      },
    );
  }
}
