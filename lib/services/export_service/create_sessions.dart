import 'package:http/http.dart' as http;
import 'dart:convert' as json;
import 'package:roadmindphone/session.dart';

/// Ajoute des sessions à un projet existant (multipart/form-data)
Future<void> createSessions({
  required http.Client client,
  required String baseUrl,
  required String projectName,
  required List<Session> sessions,
}) async {
  final encodedName = Uri.encodeComponent(projectName);
  final url = Uri.parse('$baseUrl/api/Projects/$encodedName/sessions');
  final request = http.MultipartRequest('POST', url);
  final sessionsToExport = sessions.where((s) => !s.exported).toList();
  final sessionsData = sessionsToExport
      .map(
        (session) => {
          'Name': session.name,
          'StartTime': session.startTime?.toUtc().toIso8601String(),
          'EndTime': session.endTime?.toUtc().toIso8601String(),
          'Notes': session.notes ?? '',
          'GpsPoints': session.gpsData
              .map(
                (gpsPoint) => {
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
        },
      )
      .toList();
  request.fields['SessionsData'] = json.jsonEncode(sessionsData);
  for (final session in sessionsToExport) {
    if (session.videoPath != null) {
      request.files.add(
        await http.MultipartFile.fromPath('SessionVideos', session.videoPath!),
      );
    }
  }
  final response = await client.send(request);
  final status = response.statusCode;
  final responseBody = await response.stream.bytesToString();
  if (status != 200 && status != 201) {
    throw Exception('Erreur ajout sessions: $status - $responseBody');
  }
}
