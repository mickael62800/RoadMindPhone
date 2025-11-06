import 'package:http/http.dart' as http;
import 'dart:convert' as json;
import 'dart:io' as io;
import 'package:roadmindphone/session.dart';
import 'package:roadmindphone/features/project/domain/entities/project_entity.dart';

/// Met à jour un projet existant (multipart/form-data)
Future<void> updateProject({
  required http.Client client,
  required String baseUrl,
  required ProjectEntity project,
  required List<Session> sessions,
}) async {
  final url = Uri.parse('$baseUrl/api/Projects/${project.id}');
  final request = http.MultipartRequest('PUT', url);
  final projectData = {
    'id': project.id,
    'name': project.title,
    'description': project.description ?? '',
    'sessions': sessions.map((session) => _sessionToJson(session)).toList(),
  };
  request.fields['ProjectData'] = json.jsonEncode(projectData);
  for (final session in sessions) {
    if (session.videoPath != null && io.File(session.videoPath!).existsSync()) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'sessionVideo_${session.id}',
          session.videoPath!,
        ),
      );
    }
  }
  final response = await client.send(request);
  if (response.statusCode != 200) {
    final errorBody = await response.stream.bytesToString();
    throw Exception('Erreur update: ${response.statusCode} - $errorBody');
  }
}

Map<String, dynamic> _sessionToJson(Session session) {
  final map = <String, dynamic>{
    'Id': session.id,
    'Name': session.name,
    'Notes': session.notes,
    'VideoPath': null,
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
            'Timestamp': gpsPoint.timestamp.toIso8601String(),
            'VideoTimestampMs': gpsPoint.videoTimestampMs,
          },
        )
        .toList(),
  };
  if (session.startTime != null) {
    map['StartTime'] = session.startTime!.toUtc().toIso8601String();
  }
  if (session.endTime != null) {
    map['EndTime'] = session.endTime!.toUtc().toIso8601String();
  }
  return map;
}
