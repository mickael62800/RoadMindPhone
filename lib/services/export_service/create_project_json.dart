import 'package:http/http.dart' as http;
import 'dart:convert' as json;
import 'package:roadmindphone/features/project/domain/entities/project_entity.dart';
import 'package:roadmindphone/session.dart';

/// Création d'un projet via application/json (pas de vidéos)
Future<void> createProjectJson({
  required http.Client client,
  required String baseUrl,
  required ProjectEntity project,
  required List<Session> sessions,
}) async {
  final url = Uri.parse('$baseUrl/api/Projects');
  final projectData = {
    'Name': project.title,
    'Description': project.description ?? '',
    'Sessions': sessions.map((session) => _sessionToJsonJson(session)).toList(),
  };
  final response = await client.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: json.jsonEncode(projectData),
  );
  if (response.statusCode != 201) {
    throw Exception(
      'Erreur création JSON: ${response.statusCode} - ${response.body}',
    );
  }
}

Map<String, dynamic> _sessionToJsonJson(Session session) {
  return {
    'id': session.id,
    'name': session.name,
    'startTime': session.startTime?.toUtc().toIso8601String(),
    'endTime': session.endTime?.toUtc().toIso8601String(),
    'notes': session.notes,
    'gpsPoints': session.gpsData
        .map(
          (gpsPoint) => {
            'latitude': gpsPoint.latitude,
            'longitude': gpsPoint.longitude,
            'altitude': gpsPoint.altitude,
            'speed': gpsPoint.speed,
            'heading': gpsPoint.heading,
            'timestamp': gpsPoint.timestamp.toUtc().toIso8601String(),
            'videoTimestampMs': gpsPoint.videoTimestampMs,
          },
        )
        .toList(),
  };
}
