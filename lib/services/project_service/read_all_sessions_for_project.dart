import 'package:roadmindphone/session.dart';
import 'package:roadmindphone/database_helper.dart';

/// Récupère toutes les sessions d'un projet par son id
Future<List<Session>> readAllSessionsForProject(String projectId) async {
  return await DatabaseHelper.instance.readAllSessionsForProject(projectId);
}
