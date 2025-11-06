import 'package:roadmindphone/session.dart';
import 'package:roadmindphone/database_helper.dart';

/// Met à jour une session dans la base locale
Future<void> updateSession(Session session) async {
  await DatabaseHelper.instance.updateSession(session);
}
