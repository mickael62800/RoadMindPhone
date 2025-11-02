
import 'package:flutter/material.dart';
import 'package:roadmindphone/src/ui/atoms/atoms.dart';

class StatefulWrapper extends StatelessWidget {
  final bool isLoading;
  final String? error;
  final bool isEmpty;
  final Widget child;
  final VoidCallback onRetry;
  final String emptyMessage;

  const StatefulWrapper({
    super.key,
    required this.isLoading,
    this.error,
    required this.isEmpty,
    required this.child,
    required this.onRetry,
    this.emptyMessage = 'Aucun élément pour le moment.',
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            BodyText(text: error!),
            const SizedBox(height: 16),
            PrimaryButton(onPressed: onRetry, text: 'Réessayer'),
          ],
        ),
      );
    }

    if (isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.folder_open, size: 80.0),
            const SizedBox(height: 16.0),
            BodyText(text: emptyMessage),
          ],
        ),
      );
    }

    return child;
  }
}
