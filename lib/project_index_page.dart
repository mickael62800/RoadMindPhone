import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:roadmindphone/services/project_service/read_all_sessions_for_project.dart';
import 'package:roadmindphone/services/session_service/create_session_for_project.dart';
import 'package:roadmindphone/services/project_service/delete_project.dart';
import 'package:roadmindphone/services/project_service/rename_project.dart';
import 'package:roadmindphone/src/ui/widgets/project/project_card.dart';
import 'package:roadmindphone/src/ui/widgets/project/sessions_list.dart';

import 'package:roadmindphone/export_data_page.dart';
import 'package:roadmindphone/features/project/domain/entities/project_entity.dart';

import 'package:roadmindphone/features/session/presentation/bloc/session_bloc.dart';
import 'package:roadmindphone/features/session/presentation/bloc/session_event.dart';
import 'package:roadmindphone/features/session/presentation/bloc/session_state.dart';
import 'package:roadmindphone/project.dart';
import 'package:roadmindphone/session.dart';
import 'package:roadmindphone/session_completion_page.dart';

import 'package:roadmindphone/src/ui/molecules/molecules.dart';
import 'package:roadmindphone/src/ui/organisms/organisms.dart';

/// Extension to convert legacy Project to ProjectEntity
extension ProjectToEntity on Project {
  ProjectEntity toEntity() {
    return ProjectEntity(
      id: id,
      title: title,
      description: description,
      sessionCount: sessionCount,
      duration: duration,
      createdAt: DateTime.now(), // Legacy Project doesn't have createdAt
    );
  }
}

typedef FlutterMapBuilder =
    Widget Function({
      Key? key,
      required MapOptions options,
      List<Widget>? children,
      MapController? mapController,
    });

class ProjectIndexPage extends StatefulWidget {
  final Project project;
  final FlutterMapBuilder flutterMapBuilder;

  const ProjectIndexPage({
    super.key,
    required this.project,
    this.flutterMapBuilder = _defaultFlutterMapBuilder,
  });

  static Widget _defaultFlutterMapBuilder({
    Key? key,
    required MapOptions options,
    List<Widget>? children,
    MapController? mapController,
  }) {
    return FlutterMap(
      key: key,
      options: options,
      mapController: mapController,
      children: children ?? [],
    );
  }

  @override
  State<ProjectIndexPage> createState() => _ProjectIndexPageState();
}

class _ProjectIndexPageState extends State<ProjectIndexPage> {
  late Project _project;

  @override
  void initState() {
    super.initState();
    _project = widget.project;
    Future.microtask(() {
      if (!mounted) return;
      context.read<SessionBloc>().add(LoadSessionsForProjectEvent(_project.id));
    });
  }

  void _showAddSessionDialog() async {
    final projectId = _project.id;

    final String? name = await showAddItemDialog(
      context: context,
      title: 'Nouvelle Session',
      hintText: 'Nom de la session',
    );

    if (name != null) {
      try {
        // Create session via dedicated service for immediate result
        final createdSession = await createSessionForProject(
          projectId: projectId,
          name: name,
        );

        if (!mounted) return;

        // Capture navigator before async operation
        final navigator = Navigator.of(context);
        final sessionBloc = context.read<SessionBloc>();

        await navigator.push(
          MaterialPageRoute(
            builder: (context) => SessionCompletionPage(
              session: createdSession,
              flutterMapBuilder: widget.flutterMapBuilder,
            ),
          ),
        );

        if (!mounted) return;
        // Reload sessions via SessionBloc
        sessionBloc.add(LoadSessionsForProjectEvent(projectId));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(_project.title),
        actions: <Widget>[
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'Editer') {
                _showRenameDialog();
              } else if (value == 'Supprimer') {
                _showDeleteConfirmationDialog();
              } else if (value == 'Exporter') {
                final navigator = Navigator.of(context);
                try {
                  final sessions = await readAllSessionsForProject(_project.id);
                  if (!mounted) return;
                  navigator.push(
                    MaterialPageRoute(
                      builder: (context) => ExportDataPage(
                        project: _project.toEntity(),
                        sessions: sessions,
                      ),
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Erreur lors du chargement des sessions: $e',
                      ),
                    ),
                  );
                }
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: ProjectCard(project: _project.toEntity()),
          ),
          Expanded(
            child: BlocBuilder<SessionBloc, SessionState>(
              builder: (context, state) {
                final projectId = _project.id;
                final bool isLoading = state is SessionLoading;
                final String? error = state is SessionError
                    ? state.message
                    : null;
                final List<Session> sessions;
                if (state is SessionsLoaded) {
                  sessions = state.sessions.map((entity) {
                    return Session(
                      id: entity.id,
                      projectId: entity.projectId,
                      name: entity.name,
                      duration: entity.duration,
                      gpsPoints: entity.gpsPoints,
                      videoPath: entity.videoPath,
                      gpsData: entity.gpsData,
                      startTime: entity.startTime,
                      endTime: entity.endTime,
                      notes: entity.notes,
                      exported: entity.exported,
                    );
                  }).toList();
                } else {
                  sessions = [];
                }

                return SessionsList(
                  sessions: sessions,
                  emptyMessage: 'Aucune session pour le moment.',
                  error: error,
                  isLoading: isLoading && sessions.isEmpty,
                  onRetry: () {
                    context.read<SessionBloc>().add(
                      LoadSessionsForProjectEvent(projectId),
                    );
                  },
                  formatDuration: (duration) {
                    String twoDigits(int n) => n.toString().padLeft(2, '0');
                    String twoDigitMinutes = twoDigits(
                      duration.inMinutes.remainder(60),
                    );
                    String twoDigitSeconds = twoDigits(
                      duration.inSeconds.remainder(60),
                    );
                    return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
                  },
                  onSessionTap: (session) async {
                    if (!mounted) return;
                    final navigator = Navigator.of(context);
                    final sessionBloc = context.read<SessionBloc>();
                    final bool? hasChanged = await navigator.push<bool>(
                      MaterialPageRoute(
                        builder: (context) => SessionCompletionPage(
                          session: session,
                          flutterMapBuilder: widget.flutterMapBuilder,
                        ),
                      ),
                    );
                    if (hasChanged == true && mounted) {
                      sessionBloc.add(LoadSessionsForProjectEvent(projectId));
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSessionDialog,
        tooltip: 'Ajouter Session',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showDeleteConfirmationDialog() async {
    if (!mounted) return;
    final navigator = Navigator.of(context);
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Supprimer le projet',
      content: 'Êtes-vous sûr de vouloir supprimer ce projet ?',
      confirmText: 'SUPPRIMER',
    );
    if (confirmed == true) {
      final success = await deleteProject(
        context: context,
        projectId: _project.id,
      );
      if (success && mounted) {
        navigator.pop(true);
      }
    }
  }

  void _showRenameDialog() async {
    final newTitle = await showRenameDialog(
      context: context,
      title: 'Renommer le projet',
      hintText: 'Nouveau titre du projet',
      initialValue: _project.title,
    );
    if (newTitle != null && newTitle.isNotEmpty) {
      if (!mounted) return;
      final updatedProject = _project.copy(title: newTitle).toEntity();
      final success = await renameProject(
        context: context,
        updatedProject: updatedProject,
      );
      if (success && mounted) {
        setState(() {
          _project = _project.copy(title: newTitle);
        });
      }
    }
  }
}
