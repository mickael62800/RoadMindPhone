import 'dart:io';
import 'package:roadmindphone/session.dart';
import 'package:roadmindphone/services/session_service/update_session.dart';

Future<bool> redoSession({
  required Session session,
  required Future<void> Function(Session updatedSession) onAfterRedo,
}) async {
  try {
    // Delete video file if exists
    final videoPath = session.videoPath;
    if (videoPath != null && File(videoPath).existsSync()) {
      await File(videoPath).delete();
    }
    // Clear GPS data and video path in the session
    final updatedSession = session.copy(
      gpsData: [],
      videoPath: null,
      duration: Duration.zero,
      gpsPoints: 0,
    );
    // Update directly in database
    await updateSession(updatedSession);
    await onAfterRedo(updatedSession);
    return true;
  } catch (e) {
    return false;
  }
}
