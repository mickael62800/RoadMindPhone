import 'package:roadmindphone/database_helper.dart';

/// Supprime une session de la base locale par son id
Future<void> deleteSession(String id) async {
  await DatabaseHelper.instance.deleteSession(id);
}
