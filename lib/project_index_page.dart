import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:roadmindphone/database_helper.dart';
import 'package:roadmindphone/export_data_page.dart';
import 'package:roadmindphone/features/project/domain/entities/project_entity.dart';
import 'package:roadmindphone/features/project/presentation/bloc/project_bloc.dart';
import 'package:roadmindphone/features/project/presentation/bloc/project_event.dart';
import 'package:roadmindphone/features/project/presentation/bloc/project_state.dart';
import 'package:roadmindphone/features/session/presentation/bloc/session_bloc.dart';
import 'package:roadmindphone/features/session/presentation/bloc/session_event.dart';
import 'package:roadmindphone/features/session/presentation/bloc/session_state.dart';
import 'package:roadmindphone/project.dart';
import 'package:roadmindphone/session.dart';
import 'package:roadmindphone/session_completion_page.dart';
import 'package:roadmindphone/session_index_page.dart';
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
      context.read<SessionBloc>().add(
        LoadSessionsForProjectEvent(_project.id!),
      );
    });
  }

  void _showAddSessionDialog() async {
    final projectId = _project.id!;

    final String? name = await showAddItemDialog(
      context: context,
      title: 'Nouvelle Session',
      hintText: 'Nom de la session',
    );

    if (name != null) {
      try {
        // Create session via DatabaseHelper for immediate result
        final createdSession = await DatabaseHelper.instance.createSession(
          Session(
            projectId: projectId,
            name: name,
            duration: const Duration(),
            gpsPoints: 0,
          ),
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

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
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
                // Capture navigator before async operation
                final navigator = Navigator.of(context);

                // Get sessions from DatabaseHelper for export
                final sessions = await DatabaseHelper.instance
                    .readAllSessionsForProject(_project.id!);
                if (!mounted) return;

                navigator.push(
                  MaterialPageRoute(
                    builder: (context) => ExportDataPage(
                      project: _project.toEntity(),
                      sessions: sessions,
                    ),
                  ),
                );
              } else {
                debugPrint('Value: $value');
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
      body: BlocBuilder<SessionBloc, SessionState>(
        builder: (context, state) {
          final projectId = _project.id!;

          // Determine loading state
          final bool isLoading = state is SessionLoading;

          // Determine error state
          final String? error = state is SessionError ? state.message : null;

          // Get sessions list
          final List<Session> sessions;
          if (state is SessionsLoaded) {
            sessions = state.sessions.map((entity) {
              // Convert SessionEntity back to Session for UI
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
              );
            }).toList();
          } else {
            sessions = [];
          }

          final bool isEmpty = sessions.isEmpty && !isLoading;

          return StatefulWrapper(
            isLoading: isLoading && sessions.isEmpty,
            error: error,
            isEmpty: isEmpty,
            onRetry: () {
              context.read<SessionBloc>().add(
                LoadSessionsForProjectEvent(projectId),
              );
            },
            emptyMessage: 'Aucune session pour le moment.',
            child: ItemsListView<Session>(
              items: sessions,
              titleBuilder: (session) => session.name,
              subtitleBuilder: (session) =>
                  'Durée: ${_formatDuration(session.duration)} | GPS Points: ${session.gpsPoints}',
              onTapBuilder: (session) async {
                if (!mounted) return;

                // Capture context before async operation
                final navigator = Navigator.of(context);
                final sessionBloc = context.read<SessionBloc>();

                final bool? hasChanged = await navigator.push<bool>(
                  MaterialPageRoute(
                    builder: (context) => SessionIndexPage(
                      session: session,
                      flutterMapBuilder: widget.flutterMapBuilder,
                    ),
                  ),
                );
                if (hasChanged == true && mounted) {
                  sessionBloc.add(LoadSessionsForProjectEvent(projectId));
                }
              },
            ),
          );
        },
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
    final messenger = ScaffoldMessenger.of(context);
    final projectBloc = context.read<ProjectBloc>();

    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Supprimer le projet',
      content: 'Êtes-vous sûr de vouloir supprimer ce projet ?',
      confirmText: 'SUPPRIMER',
    );

    if (confirmed == true) {
      projectBloc.add(DeleteProjectEvent(projectId: _project.id!));

      // Wait for the deletion result
      await for (final state in projectBloc.stream) {
        if (state is ProjectOperationSuccess) {
          if (!mounted) return;
          messenger.showSnackBar(
            const SnackBar(content: Text('Projet supprimé')),
          );
          navigator.pop(true); // Return true to indicate deletion
          break;
        } else if (state is ProjectError) {
          if (!mounted) return;
          messenger.showSnackBar(
            SnackBar(content: Text('Erreur: ${state.message}')),
          );
          break;
        }
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
      final projectBloc = context.read<ProjectBloc>();
      final updatedProject = _project.copy(title: newTitle);
      final messenger = ScaffoldMessenger.of(context);

      projectBloc.add(UpdateProjectEvent(project: updatedProject.toEntity()));

      // Wait for the update result
      await for (final state in projectBloc.stream) {
        if (state is ProjectOperationSuccess) {
          if (!mounted) return;
          setState(() {
            _project = updatedProject;
          });
          messenger.showSnackBar(
            const SnackBar(content: Text('Projet renommé avec succès')),
          );
          break;
        } else if (state is ProjectError) {
          if (!mounted) return;
          messenger.showSnackBar(
            SnackBar(content: Text('Erreur: ${state.message}')),
          );
          break;
        }
      }
    }
  }
}
