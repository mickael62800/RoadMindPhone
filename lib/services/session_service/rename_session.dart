import 'package:roadmindphone/session.dart';
import 'package:roadmindphone/services/session_service/update_session.dart';
import 'package:flutter/material.dart';

Future<bool> renameSession({
  required BuildContext context,
  required Session session,
  required String newName,
  required void Function(Session updatedSession) onSuccess,
}) async {
  try {
    final updatedSession = session.copy(name: newName);
    await updateSession(updatedSession);
    onSuccess(updatedSession);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Session renommée avec succès')),
    );
    return true;
  } catch (e) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Erreur lors du renommage: $e')));
    return false;
  }
}
