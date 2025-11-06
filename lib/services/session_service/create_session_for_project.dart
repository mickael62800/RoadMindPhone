import 'package:roadmindphone/session.dart';
import 'package:roadmindphone/database_helper.dart';
import 'package:uuid/uuid.dart';

/// Crée une nouvelle session pour un projet donné avec un nom
Future<Session> createSessionForProject({
  required String projectId,
  required String name,
}) async {
  final session = Session(
    id: const Uuid().v4(),
    projectId: projectId,
    name: name,
    duration: const Duration(),
    gpsPoints: 0,
    exported: false,
    videoPath: null,
  );
  return await DatabaseHelper.instance.createSession(session);
}
