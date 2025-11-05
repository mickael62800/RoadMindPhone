import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
import 'dart:io' as io;
import 'dart:convert' as json;
import 'package:roadmindphone/session.dart';
import 'package:roadmindphone/features/project/domain/entities/project_entity.dart';

class ExportService {
  /// Vérifie si un projet existe par son nom (HEAD /api/Projects/exists/{name})
  Future<bool> checkProjectExistsByName(String projectName) async {
    final encodedName = Uri.encodeComponent(projectName);
    final url = Uri.parse('$baseUrl/api/Projects/exists/$encodedName');
    final response = await client.head(url);
    if (response.statusCode == 200) return true;
    if (response.statusCode == 404) return false;
    throw Exception(
      'Erreur lors de la vérification par nom: ${response.statusCode}',
    );
  }

  final http.Client client;
  final String baseUrl;

  ExportService({required this.client, required this.baseUrl});

  /// Ajoute des sessions à un projet existant (multipart/form-data)
  Future<void> createSessions(
    String projectName,
    List<Session> sessions,
  ) async {
    final encodedName = Uri.encodeComponent(projectName);
    final url = Uri.parse('$baseUrl/api/Projects/$encodedName/sessions');
    final request = http.MultipartRequest('POST', url);
    // Préparer le JSON SessionsData
    final sessionsData = sessions
        .map((session) => _sessionToJsonJson(session))
        .toList();
    request.files.add(
      http.MultipartFile.fromString(
        'SessionsData',
        json.jsonEncode(sessionsData),
        contentType: MediaType('application', 'json'),
      ),
    );
    // Ajouter les vidéos
    for (final session in sessions) {
      if (session.videoPath != null &&
          io.File(session.videoPath!).existsSync()) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'sessionVideo_${session.id}',
            session.videoPath!,
          ),
        );
      }
    }
    final response = await client.send(request);
    if (response.statusCode != 200 && response.statusCode != 201) {
      final errorBody = await response.stream.bytesToString();
      throw Exception(
        'Erreur ajout sessions: ${response.statusCode} - $errorBody',
      );
    }
  }

  /// Création d'un projet via application/json (pas de vidéos)
  Future<void> createProjectJson(
    ProjectEntity project,
    List<Session> sessions,
  ) async {
    final url = Uri.parse('$baseUrl/api/Projects');
    final projectData = {
      'Name': project.title,
      'Description': project.description ?? '',
      'Sessions': sessions
          .map((session) => _sessionToJsonJson(session))
          .toList(),
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
      'id': session.id ?? 0,
      'name': session.name,
      'startTime': session.startTime?.toIso8601String(),
      'endTime': session.endTime?.toIso8601String(),
      'notes': session.notes,
      'gpsPoints': session.gpsData
          .map(
            (gpsPoint) => {
              'latitude': gpsPoint.latitude,
              'longitude': gpsPoint.longitude,
              'altitude': gpsPoint.altitude,
              'speed': gpsPoint.speed,
              'heading': gpsPoint.heading,
              'timestamp': gpsPoint.timestamp.toIso8601String(),
              'videoTimestampMs': gpsPoint.videoTimestampMs,
            },
          )
          .toList(),
    };
  }

  Future<bool> checkProjectExists(int projectId) async {
    final url = Uri.parse('$baseUrl/api/Projects/$projectId');
    final response = await client.head(url);
    if (response.statusCode == 200) return true;
    if (response.statusCode == 404) return false;
    throw Exception('Erreur lors de la vérification: ${response.statusCode}');
  }

  Future<void> createProject(
    ProjectEntity project,
    List<Session> sessions,
  ) async {
    final url = Uri.parse('$baseUrl/api/Projects');
    final request = http.MultipartRequest('POST', url);
    final projectData = {
      'Name': project.title,
      'Description': project.description ?? '',
      'Sessions': sessions.map((session) => _sessionToJson(session)).toList(),
    };
    request.fields['ProjectData'] = json.jsonEncode(projectData);
    for (final session in sessions) {
      if (session.videoPath != null &&
          io.File(session.videoPath!).existsSync()) {
        debugPrint(
          '[EXPORT] Ajout vidéo : sessionVideo_${session.id} => ${session.videoPath!}',
        );
        request.files.add(
          await http.MultipartFile.fromPath(
            'sessionVideo_${session.id}',
            session.videoPath!,
          ),
        );
      } else {
        debugPrint('[EXPORT] Pas de vidéo pour session ${session.id}');
      }
    }
    final response = await client.send(request);
    if (response.statusCode != 201) {
      final errorBody = await response.stream.bytesToString();
      throw Exception('Erreur création: ${response.statusCode} - $errorBody');
    }
  }

  Future<void> updateProject(
    ProjectEntity project,
    List<Session> sessions,
  ) async {
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
      if (session.videoPath != null &&
          io.File(session.videoPath!).existsSync()) {
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
      'Id': session.id ?? 0,
      'Name': session.name,
      'Notes': session.notes,
      'VideoPath': null,
      'GpsPoints': session.gpsData
          .map(
            (gpsPoint) => {
              'Id': gpsPoint.id ?? 0,
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
      map['StartTime'] = session.startTime!.toIso8601String();
    }
    if (session.endTime != null) {
      map['EndTime'] = session.endTime!.toIso8601String();
    }
    return map;
  }
}
