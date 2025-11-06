import 'package:roadmindphone/session.dart';
import 'package:roadmindphone/database_helper.dart';

/// Marque une liste de sessions comme exportées dans la base locale
Future<void> markSessionsExported(List<Session> sessions) async {
  for (final session in sessions) {
    final exportedSession = session.copy(exported: true);
    await DatabaseHelper.instance.updateSession(exportedSession);
  }
}
