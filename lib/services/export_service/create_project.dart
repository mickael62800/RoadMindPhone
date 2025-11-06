import 'package:http/http.dart' as http;
import 'dart:convert' as json;
import 'dart:io' as io;
import 'package:roadmindphone/session.dart';
import 'package:roadmindphone/features/project/domain/entities/project_entity.dart';

/// Création d'un projet avec vidéos (multipart/form-data)
Future<void> createProject({
  required http.Client client,
  required String baseUrl,
  required ProjectEntity project,
  required List<Session> sessions,
}) async {
  final url = Uri.parse('$baseUrl/api/Projects');
  final request = http.MultipartRequest('POST', url);
  final List<Map<String, dynamic>> sessionsJson = sessions
      .map((session) => _sessionToJson(session, project.id))
      .toList();
  final projectData = {
    'Id': project.id,
    'Name': project.title,
    'Description': project.description ?? '',
    'Sessions': sessionsJson,
  };
  request.fields['ProjectData'] = json.jsonEncode(projectData);
  for (final session in sessions) {
    if (session.videoPath != null && io.File(session.videoPath!).existsSync()) {
      request.files.add(
        await http.MultipartFile.fromPath('SessionVideos', session.videoPath!),
      );
    }
  }
  final response = await client.send(request);
  if (response.statusCode != 201) {
    final errorBody = await response.stream.bytesToString();
    throw Exception('Erreur création: ${response.statusCode} - $errorBody');
  }
}

Map<String, dynamic> _sessionToJson(Session session, String projectId) {
  final map = <String, dynamic>{
    'Id': session.id,
    'ProjectId': projectId,
    'Name': session.name,
    'StartTime': session.startTime?.toUtc().toIso8601String(),
    'EndTime': session.endTime?.toUtc().toIso8601String(),
    'Notes': session.notes,
    'GpsPoints': session.gpsData
        .map(
          (gpsPoint) => {
            'Id': gpsPoint.id,
            'SessionId': gpsPoint.sessionId,
            'Latitude': gpsPoint.latitude,
            'Longitude': gpsPoint.longitude,
            'Altitude': gpsPoint.altitude,
            'Speed': gpsPoint.speed,
            'Heading': gpsPoint.heading,
            'Timestamp': gpsPoint.timestamp.toUtc().toIso8601String(),
            'VideoTimestampMs': gpsPoint.videoTimestampMs,
          },
        )
        .toList(),
  };
  return map;
}
