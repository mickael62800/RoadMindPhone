import 'dart:io';

import 'package:flutter/material.dart';
import 'package:roadmindphone/database_helper.dart';
import 'package:roadmindphone/settings_page.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:roadmindphone/session.dart'; // Import Session class
import 'package:roadmindphone/project_index_page.dart';

Future<void> main() async {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      showSemanticsDebugger: true, // Add this line
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.dark,
      home: const MyHomePage(title: 'Liste des Projets'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Future<List<Project>> _projects;

  @override
  void initState() {
    super.initState();
    _refreshProjects();
  }

  Future<void> _refreshProjects() async {
    setState(() {
      _projects = DatabaseHelper.instance.readAllProjects();
    });
  }

  Future<void> _addProject(String title) async {
    final project = Project(title: title);
    await DatabaseHelper.instance.create(project);
    _refreshProjects();
  }

  void _showAddProjectDialog() async {
    final TextEditingController controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nouveau Projet'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: "Titre du projet"),
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
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  _addProject(controller.text);
                }
                Navigator.of(context).pop();
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
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Project>>(
        future: _projects,
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
                  Text('Aucun projet pour le moment.'),
                ],
              ),
            );
          }
          else {
            final projects = snapshot.data!;
            return OrientationBuilder(
              builder: (context, orientation) {
                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: orientation == Orientation.portrait ? 1 : 3,
                    childAspectRatio: orientation == Orientation.portrait ? 4 : 2,
                  ),
                  itemCount: projects.length,
                  itemBuilder: (context, index) {
                    final project = projects[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                      elevation: 4.0,
                      child: ListTile(
                        title: Text(project.title),
                        subtitle: Text('Sessions: ${project.sessionCount} | Durée: ${_formatDuration(project.duration)}'),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProjectIndexPage(project: project),
                            ),
                          );
                          _refreshProjects();
                        },
                      ),
                    );
                  },
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProjectDialog,
        tooltip: 'Add Project',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class Project {
  final int? id;
  final String title;
  final String? description;
  final int sessionCount;
  final Duration duration;
  final List<Session>? sessions; // Add sessions field

  Project({
    this.id,
    required this.title,
    this.description,
    this.sessionCount = 0,
    this.duration = Duration.zero,
    this.sessions, // Initialize sessions
  });

  Project copy({
    int? id,
    String? title,
    String? description,
    int? sessionCount,
    Duration? duration,
    List<Session>? sessions,
  }) =>
      Project(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        sessionCount: sessionCount ?? this.sessionCount,
        duration: duration ?? this.duration,
        sessions: sessions ?? this.sessions,
      );

  static Project fromMap(Map<String, dynamic> map) => Project(
        id: map['id'] as int?,
        title: map['title'] as String,
        description: map['description'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
      };
}
