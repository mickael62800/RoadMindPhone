import 'package:flutter/material.dart';
import 'package:roadmindphone/features/project/domain/entities/project_entity.dart';
import 'package:roadmindphone/session.dart';
import 'package:http/http.dart' as http;
import 'dart:io' as io;
import 'dart:convert' as json;

class ExportDataPage extends StatefulWidget {
  final ProjectEntity project;
  final List<Session> sessions; // Add sessions list
  final http.Client? httpClient; // Add optional http.Client

  const ExportDataPage({
    super.key,
    required this.project,
    this.sessions = const [],
    this.httpClient,
  });

  @override
  State<ExportDataPage> createState() => _ExportDataPageState();
}

class _ExportDataPageState extends State<ExportDataPage> {
  bool _projectExists = false;
  late final http.Client _client; // Use injected client

  @override
  void initState() {
    super.initState();
    _client = widget.httpClient ?? http.Client(); // Initialize client
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkProjectExists();
      }
    });
  }

  Future<void> _checkProjectExists() async {
    try {
      final response = await _client.head(
        Uri.parse('http://192.168.1.10:5160/api/Projects/${widget.project.id}'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _projectExists = true;
        });
      } else if (response.statusCode == 404) {
        setState(() {
          _projectExists = false;
        });
      } else {
        // Handle other status codes
        debugPrint('Error checking project existence: ${response.statusCode}');
        setState(() {
          _projectExists = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Erreur lors de la vérification de l\'existence du projet: ${response.statusCode}',
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error checking project existence: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur lors de la vérification de l\'existence du projet: $e',
            ),
          ),
        );
      }
      setState(() {
        _projectExists = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Exporter les données pour ${widget.project.title}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _projectExists
                ? const Text(
                    'Le projet existe dans la base de données distante.',
                  )
                : const Text(
                    'Le projet n\'existe PAS dans la base de données distante.',
                  ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_projectExists) {
                  _updateProject();
                } else {
                  _createProject();
                }
              },
              child: Text(
                _projectExists ? 'Mettre à jour le projet' : 'Créer le projet',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createProject() async {
    final url = Uri.parse('http://192.168.1.10:5160/api/Projects');
    final request = http.MultipartRequest('POST', url);

    // Prepare ProjectData JSON
    final projectData = {
      'name': widget.project.title,
      'description': widget.project.description ?? '',
      'sessions': widget.sessions
          .map(
            (session) => {
              'id': session.id ?? 0, // Provide 0 if id is null
              'name': session.name,
              'startTime': session.startTime?.toIso8601String(),
              'endTime': session.endTime?.toIso8601String(),
              'notes': session.notes,
              'videoPath': null, // Will be filled by API
              'gpsPoints': session.gpsData
                  .map(
                    (gpsPoint) => {
                      'id': gpsPoint.id ?? 0, // Provide 0 if id is null
                      'sessionId': gpsPoint.sessionId,
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
            },
          )
          .toList(),
    };

    request.fields['ProjectData'] = json.jsonEncode(projectData);

    // Add video files
    for (final session in widget.sessions) {
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

    try {
      final response = await _client.send(request);
      if (response.statusCode == 201) {
        final responseBody = await response.stream.bytesToString();
        debugPrint('Project created successfully: $responseBody');
        if (!mounted) return;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Projet créé avec succès !')),
          );
          setState(() {
            _projectExists = true; // Project now exists on the remote server
          });
        }
      } else {
        final errorBody = await response.stream.bytesToString();
        debugPrint(
          'Error creating project: ${response.statusCode} - $errorBody',
        );
        if (!mounted) return;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Échec de la création du projet: ${response.statusCode}',
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error creating project: $e');
      if (!mounted) return;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la création du projet: $e')),
        );
      }
    }
  }

  Future<void> _updateProject() async {
    final url = Uri.parse(
      'http://192.168.1.10:5160/api/Projects/${widget.project.id}',
    );
    final request = http.MultipartRequest('PUT', url);

    // Prepare ProjectData JSON
    final projectData = {
      'id': widget.project.id,
      'name': widget.project.title,
      'description': widget.project.description ?? '',
      'sessions': widget.sessions
          .map(
            (session) => {
              'id':
                  session.id ??
                  0, // Use actual ID for existing sessions, temporary for new ones
              'projectId': widget.project.id,
              'name': session.name,
              'startTime': session.startTime?.toIso8601String(),
              'endTime': session.endTime?.toIso8601String(),
              'notes': session.notes,
              'videoPath': session.videoPath, // Keep existing path or null
              'gpsPoints': session.gpsData
                  .map(
                    (gpsPoint) => {
                      'id':
                          gpsPoint.id ??
                          0, // Use actual ID for existing GPS points, 0 for new ones
                      'sessionId': session.id ?? 0,
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
            },
          )
          .toList(),
    };

    request.fields['ProjectData'] = json.jsonEncode(projectData);

    // Add video files (for new or updated videos)
    for (final session in widget.sessions) {
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

    try {
      final response = await _client.send(request);
      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        debugPrint('Project updated successfully: $responseBody');
        if (!mounted) return;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Projet mis à jour avec succès !')),
          );
        }
      } else {
        final errorBody = await response.stream.bytesToString();
        debugPrint(
          'Error updating project: ${response.statusCode} - $errorBody',
        );
        if (!mounted) return;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Échec de la mise à jour du projet: ${response.statusCode}',
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error updating project: $e');
      if (!mounted) return;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la mise à jour du projet: $e'),
          ),
        );
      }
    }
  }
}
