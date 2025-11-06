import 'package:roadmindphone/session.dart';
import 'package:roadmindphone/database_helper.dart';

/// Crée une session dans la base locale
Future<Session> createSession(Session session) async {
  return await DatabaseHelper.instance.createSession(session);
}
