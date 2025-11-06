import 'package:roadmindphone/session.dart';
import 'package:roadmindphone/services/session_service/update_session.dart';
import 'package:roadmindphone/session_gps_point.dart';

/// Met à jour et sauvegarde une session avec les nouvelles données (durée, GPS, vidéo, etc.)
Future<Session> finalizeSession({
  required Session session,
  required Duration duration,
  required List<SessionGpsPoint> gpsData,
  String? videoPath,
  DateTime? endTime,
}) async {
  final updatedSession = session.copy(
    duration: duration,
    gpsPoints: gpsData.length,
    gpsData: gpsData,
    videoPath: videoPath,
    endTime: endTime ?? DateTime.now().toUtc(),
  );
  await updateSession(updatedSession);
  return updatedSession;
}
