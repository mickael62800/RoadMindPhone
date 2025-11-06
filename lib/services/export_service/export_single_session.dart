import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:roadmindphone/session.dart';

/// Exporte une session unique vers l'API backend (POST /api/Sessions)
Future<http.Response> exportSingleSession({
  required http.Client client,
  required String baseUrl,
  required Session session,
}) async {
  final sessionData = {
    'id': session.id,
    'projectId': session.projectId,
    'name': session.name,
    'duration': session.duration.inMilliseconds,
    'gpsPointsCount': session.gpsPoints,
    'videoPath': session.videoPath,
    'gpsData': session.gpsData.map((gpsPoint) => gpsPoint.toMap()).toList(),
  };

  final url = Uri.parse('$baseUrl/api/Sessions');
  final response = await client.post(
    url,
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(sessionData),
  );
  return response;
}
