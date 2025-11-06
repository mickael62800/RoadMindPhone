import 'package:roadmindphone/project.dart';
import 'package:roadmindphone/database_helper.dart';

/// Crée un projet dans la base locale SQLite
Future<Project> createProjectLocal(Project project) async {
  return await DatabaseHelper.instance.create(project);
}
