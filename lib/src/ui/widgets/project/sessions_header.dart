import 'package:flutter/material.dart';

class SessionsHeader extends StatelessWidget {
  final VoidCallback onAddSession;
  const SessionsHeader({super.key, required this.onAddSession});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Sessions', style: Theme.of(context).textTheme.titleLarge),
        ElevatedButton.icon(
          onPressed: onAddSession,
          icon: const Icon(Icons.add),
          label: const Text('Nouvelle session'),
        ),
      ],
    );
  }
}
