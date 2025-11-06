import 'dart:io';
import 'package:roadmindphone/session.dart';
import 'package:roadmindphone/services/session_service/delete_session.dart';

Future<bool> deleteSessionWithFile({required Session session}) async {
  try {
    await deleteSession(session.id);
    final videoPath = session.videoPath;
    if (videoPath != null && File(videoPath).existsSync()) {
      await File(videoPath).delete();
    }
    return true;
  } catch (e) {
    return false;
  }
}
