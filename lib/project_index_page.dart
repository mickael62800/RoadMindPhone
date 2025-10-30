import 'package:flutter/material.dart';
import 'package:roadmindphone/database_helper.dart';
import 'package:roadmindphone/main.dart';

import 'package:roadmindphone/session_completion_page.dart';
import 'package:roadmindphone/session_index_page.dart';
import 'package:roadmindphone/export_data_page.dart';

import 'dart:convert';

import 'package:roadmindphone/session_gps_point.dart';

class Session {
  final int? id;
  final int projectId;
  final String name;
  final Duration duration;
  final int gpsPoints;
  final String? videoPath;
  final List<SessionGpsPoint> gpsData;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? notes;

  Session({
    this.id,
    required this.projectId,
    required this.name,
    required this.duration,
    required this.gpsPoints,
    this.videoPath,
    this.gpsData = const [],
    this.startTime,
    this.endTime,
    this.notes,
  });

  Session copy({
    int? id,
    int? projectId,
    String? name,
    Duration? duration,
    int? gpsPoints,
    String? videoPath,
    List<SessionGpsPoint>? gpsData,
    DateTime? startTime,
    DateTime? endTime,
    String? notes,
  }) =>
      Session(
        id: id ?? this.id,
        projectId: projectId ?? this.projectId,
        name: name ?? this.name,
        duration: duration ?? this.duration,
        gpsPoints: gpsPoints ?? this.gpsPoints,
        videoPath: videoPath ?? this.videoPath,
        gpsData: gpsData ?? this.gpsData,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        notes: notes ?? this.notes,
      );

  static Session fromMap(Map<String, dynamic> map) => Session(
        id: map['id'] as int?,
        projectId: map['projectId'] as int,
        name: map['name'] as String,
        duration: Duration(milliseconds: map['duration'] as int),
        gpsPoints: map['gpsPoints'] as int,
        videoPath: map['videoPath'] as String?,
        gpsData: map['gpsData'] == null
            ? []
            : (json.decode(map['gpsData'] as String) as List)
                .map((e) => SessionGpsPoint.fromMap(e as Map<String, dynamic>))
                .toList(),
        startTime: map['startTime'] != null ? DateTime.parse(map['startTime'] as String) : null,
        endTime: map['endTime'] != null ? DateTime.parse(map['endTime'] as String) : null,
        notes: map['notes'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'projectId': projectId,
        'name': name,
        'duration': duration.inMilliseconds,
        'gpsPoints': gpsPoints,
        'videoPath': videoPath,
        'gpsData': json.encode(gpsData.map((e) => e.toMap()).toList()),
        'startTime': startTime?.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'notes': notes,
      };
}

class ProjectIndexPage extends StatefulWidget {
  final Project project;

  const ProjectIndexPage({super.key, required this.project});

  @override
  State<ProjectIndexPage> createState() => _ProjectIndexPageState();
}

class _ProjectIndexPageState extends State<ProjectIndexPage> {
  late Project _project;
  late Future<List<Session>> _sessions;

  @override
  void initState() {
    super.initState();
    _project = widget.project;
    _refreshSessions();
  }

  Future<void> _refreshSessions() async {
    setState(() {
      _sessions = DatabaseHelper.instance.readAllSessionsForProject(_project.id!);
    });
  }

  Future<Session> _addSession(String name) async {
    final session = Session(
      projectId: _project.id!,
      name: name,
      duration: Duration.zero, // Default duration
      gpsPoints: 0,
    );
    final newSession = await DatabaseHelper.instance.createSession(session);
    _refreshSessions();
    return newSession;
  }

  void _showAddSessionDialog() async {
    final TextEditingController controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nouvelle Session'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: "Nom de la session"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('ANNULER'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('AJOUTER'),
              onPressed: () async {
                if (controller.text.isNotEmpty) {
                  final newSession = await _addSession(controller.text);
                  Navigator.of(context).pop(); // Close the dialog
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          SessionCompletionPage(session: newSession),
                    ),
                  );
                  _refreshSessions();
                } else {
                  Navigator.of(context).pop(); // Close the dialog
                }
              },
            ),
          ],
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(_project.title),
        actions: <Widget>[
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'Editer') {
                _showRenameDialog();
              } else if (value == 'Supprimer') {
                _showDeleteConfirmationDialog();
              } else if (value == 'Exporter') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ExportDataPage(project: _project)),
                );
              } else {
                print('Value: $value');
              }
            },
            itemBuilder: (BuildContext context) {
              return {'Editer', 'Supprimer', 'Exporter'}.map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(choice),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Session>>(
        future: _sessions,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(Icons.folder_open, size: 80.0),
                  SizedBox(height: 16.0),
                  Text('Aucune session pour le moment.'),
                ],
              ),
            );
          } else {
            final sessions = snapshot.data!;
            Widget sessionCard(Session session) {
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                elevation: 4.0,
                child: ListTile(
                  title: Text(session.name),
                  subtitle: Text('Durée: ${_formatDuration(session.duration)} | GPS Points: ${session.gpsPoints}'),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SessionIndexPage(session: session),
                      ),
                    );
                    _refreshSessions();
                  },
                ),
              );
            }

            return OrientationBuilder(
              builder: (context, orientation) {
                if (orientation == Orientation.landscape) {
                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 4,
                    ),
                    itemCount: sessions.length,
                    itemBuilder: (context, index) {
                      final session = sessions[index];
                      return sessionCard(session);
                    },
                  );
                } else {
                  return ListView.builder(
                    itemCount: sessions.length,
                    itemBuilder: (context, index) {
                      final session = sessions[index];
                      return sessionCard(session);
                    },
                  );
                }
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSessionDialog,
        tooltip: 'Ajouter Session',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Supprimer le projet'),
          content: const Text('Êtes-vous sûr de vouloir supprimer ce projet ?'),
          actions: <Widget>[
            TextButton(
              child: const Text('ANNULER'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('SUPPRIMER'),
              onPressed: () async {
                await DatabaseHelper.instance.delete(_project.id!);
                Navigator.of(context).pop(); // Close the dialog
                Navigator.of(context).pop(); // Go back to the previous screen
              },
            ),
          ],
        );
      },
    );
  }

  void _showRenameDialog() async {
    final TextEditingController controller = TextEditingController(text: _project.title);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Renommer le projet'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: "Nouveau titre du projet"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('ANNULER'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('RENOMMER'),
              onPressed: () {
                Navigator.of(context).pop(controller.text);
              },
            ),
          ],
        );
      },
    );

    if (newTitle != null && newTitle.isNotEmpty) {
      final updatedProject = _project.copy(title: newTitle);
      await DatabaseHelper.instance.update(updatedProject);
      setState(() {
        _project = updatedProject;
      });
    }
  }

}
