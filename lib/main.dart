import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:roadmindphone/core/di/injection_container.dart';
import 'package:roadmindphone/features/project/presentation/bloc/project_bloc.dart';
import 'package:roadmindphone/features/project/presentation/pages/pages.dart';
import 'package:roadmindphone/project_index_page.dart';
import 'package:roadmindphone/session.dart';
import 'package:roadmindphone/settings_page.dart';
import 'package:roadmindphone/src/ui/organisms/add_item_dialog.dart';
import 'package:roadmindphone/src/ui/organisms/items_list_view.dart';
import 'package:roadmindphone/src/ui/organisms/stateful_wrapper.dart';
import 'package:roadmindphone/stores/project_store.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Main entry point of the application
///
/// Initializes dependencies and runs the app with Clean Architecture
/// and BLoC pattern for state management.
Future<void> main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize sqflite for desktop platforms
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Initialize all dependencies (DI container)
  await initializeDependencies();

  // Run the app
  runApp(const MyApp());
}

/// Root application widget
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RoadMind Phone',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: ThemeMode.dark,
      // Provide ProjectBloc at the root level
      home: BlocProvider(
        create: (_) => sl<ProjectBloc>(),
        child: const ProjectListPage(),
      ),
    );
  }
}

/// Legacy Project class for backward compatibility
///
/// This class is kept to maintain compatibility with:
/// - database_helper.dart
/// - Existing tests (project_test.dart)
/// - Old pages not yet migrated (project_index_page.dart, etc.)
///
/// New code should use ProjectEntity from the Clean Architecture.
class Project {
  final int? id;
  final String title;
  final String? description;
  final int sessionCount;
  final Duration duration;
  final List<Session>? sessions;

  Project({
    this.id,
    required this.title,
    this.description,
    this.sessionCount = 0,
    this.duration = Duration.zero,
    this.sessions,
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

/// Legacy MyHomePage widget for backward compatibility with tests
///
/// This widget is kept to maintain compatibility with:
/// - test/main_page_widget_test.dart
/// - test/main_page_with_store_test.dart
///
/// New code should use ProjectListPage from Clean Architecture.
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

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
