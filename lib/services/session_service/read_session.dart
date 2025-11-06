import 'package:roadmindphone/session.dart';
import 'package:roadmindphone/database_helper.dart';

/// Lit une session depuis la base locale par son id
Future<Session> readSession(String id) async {
  return await DatabaseHelper.instance.readSession(id);
}
