import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roadmindphone/settings_page.dart';
import 'package:roadmindphone/stores/project_store.dart';
import 'package:roadmindphone/stores/session_store.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:roadmindphone/session.dart'; // Import Session class
import 'package:roadmindphone/project_index_page.dart';

import 'package:roadmindphone/src/ui/organisms/organisms.dart';

Future<void> main() async {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProjectStore()),
        ChangeNotifierProvider(create: (_) => SessionStore()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      showSemanticsDebugger: false,
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
  @override
  void initState() {
    super.initState();
    // Charger les projets au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProjectStore>().loadProjects().catchError((_) {
        // L'état d'erreur est déjà géré par le store et l'UI.
      });
    });
  }

  Future<void> _addProject(String title) async {
    try {
      await context.read<ProjectStore>().createProject(title);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Projet créé avec succès')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  void _showAddProjectDialog() async {
    final String? title = await showAddItemDialog(
      context: context,
      title: 'Nouveau Projet',
      hintText: 'Titre du projet',
    );
    if (title != null) {
      _addProject(title);
    }
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
      body: Consumer<ProjectStore>(
        builder: (context, store, child) {
          return StatefulWrapper(
            isLoading: store.isLoading,
            error: store.error,
            isEmpty: !store.hasProjects,
            onRetry: () {
              store.clearError();
              store.loadProjects();
            },
            emptyMessage: 'Aucun projet pour le moment.',
            child: ItemsListView<Project>(
              items: store.projects,
              titleBuilder: (project) => project.title,
              subtitleBuilder: (project) =>
                  'Sessions: ${project.sessionCount} | Durée: ${_formatDuration(project.duration)}',
              onTapBuilder: (project) async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProjectIndexPage(project: project),
                  ),
                );
                // Rafraîchir les projets après retour
                if (context.mounted) {
                  context.read<ProjectStore>().loadProjects();
                }
              },
            ),
          );
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
  }) => Project(
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
