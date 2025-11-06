import 'package:roadmindphone/session.dart';
import 'package:roadmindphone/database_helper.dart';
import 'package:roadmindphone/features/project/domain/entities/project_entity.dart';

/// Calcule les statistiques additionnelles pour une liste de projets
Future<Map<String, dynamic>> computeProjectStats(
  List<ProjectEntity> projects,
) async {
  int gpsPoints = 0;
  int videos = 0;
  Map<String, bool> warnings = {};

  for (final project in projects) {
    final sessions = await DatabaseHelper.instance.readAllSessionsForProject(
      project.id,
    );
    bool hasIncomplete = false;
    for (final session in sessions) {
      gpsPoints += session.gpsPoints;
      if (session.videoPath != null && session.videoPath!.isNotEmpty) {
        videos++;
      }
      if (session.videoPath == null ||
          session.videoPath!.isEmpty ||
          session.gpsPoints == 0) {
        hasIncomplete = true;
      }
    }
    warnings[project.id] = hasIncomplete;
  }

  return {'gpsPoints': gpsPoints, 'videos': videos, 'warnings': warnings};
}
