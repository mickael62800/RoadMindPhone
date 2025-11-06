import 'package:roadmindphone/src/ui/widgets/project/sessions_header.dart';
import 'package:roadmindphone/src/ui/widgets/project/project_sessions_list.dart';
import 'package:roadmindphone/src/ui/widgets/project/project_info_card.dart';
import 'package:roadmindphone/services/session_service/create_session_for_project.dart';
import 'package:roadmindphone/services/project_service/read_all_sessions_for_project.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roadmindphone/features/project/presentation/bloc/bloc.dart';
import 'package:roadmindphone/features/project/domain/entities/project_entity.dart';
import 'package:roadmindphone/src/ui/molecules/molecules.dart';
import 'package:roadmindphone/session.dart';
import 'package:roadmindphone/export_data_page.dart';
import 'package:roadmindphone/session_completion_page.dart';
import 'package:roadmindphone/session_index_page.dart';
import 'package:roadmindphone/src/ui/organisms/organisms.dart';

/// Page displaying project details with edit and delete options
///
/// Uses ProjectBloc to manage project operations.
/// Follows Clean Architecture principles with BLoC pattern.
class ProjectDetailPage extends StatefulWidget {
  final ProjectEntity project;

  const ProjectDetailPage({super.key, required this.project});

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> {
  late ProjectEntity _project;
  late Future<List<Session>> _sessionsFuture;

  @override
  void initState() {
    super.initState();
    _project = widget.project;
    _refreshSessions();
  }

  /// Refresh the sessions list and reload project data
  void _refreshSessions() {
    setState(() {
      _sessionsFuture = readAllSessionsForProject(_project.id);
    });

    // Reload project data to update session count and duration
    context.read<ProjectBloc>().add(GetProjectEvent(projectId: _project.id));
  }

  /// Update project data when bloc state changes

  /// Format duration to HH:MM:SS
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
  }

  /// Show dialog to rename the project
  void _showRenameDialog() async {
    final newTitle = await showRenameDialog(
      context: context,
      title: 'Renommer le projet',
      hintText: 'Nouveau titre du projet',
      initialValue: _project.title,
    );

    if (newTitle != null && newTitle.isNotEmpty && newTitle != _project.title) {
      if (!mounted) return;

      final updatedProject = _project.copyWith(
        title: newTitle,
        updatedAt: DateTime.now(),
      );

      context.read<ProjectBloc>().add(
        UpdateProjectEvent(project: updatedProject),
      );

      setState(() {
        _project = updatedProject;
      });
    }
  }

  /// Show dialog to confirm project deletion
  void _showDeleteConfirmationDialog() async {
    if (!mounted) return;

    // Capture context before async operation
    final navigator = Navigator.of(context);
    final projectBloc = context.read<ProjectBloc>();

    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Supprimer le projet',
      content:
          'Êtes-vous sûr de vouloir supprimer ce projet ? Cette action est irréversible.',
      confirmText: 'SUPPRIMER',
    );

    if (confirmed == true) {
      if (!mounted) return;

      projectBloc.add(DeleteProjectEvent(projectId: _project.id));

      // Return to previous screen after a short delay
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      navigator.pop(true); // Return true to indicate deletion
    }
  }

  /// Show export data page for this project
  void _showExportPage() async {
    if (!mounted) return;

    // Capture navigator before async operation
    final navigator = Navigator.of(context);

    try {
      // Utiliser le service pour obtenir les sessions du projet
      final sessions = await readAllSessionsForProject(_project.id);

      if (!mounted) return;

      navigator.push(
        MaterialPageRoute(
          builder: (context) =>
              ExportDataPage(project: _project, sessions: sessions),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement des sessions: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Show dialog to add a new session
  void _showAddSessionDialog() async {
    final String? name = await showAddItemDialog(
      context: context,
      title: 'Nouvelle Session',
      hintText: 'Nom de la session',
    );

    if (name != null && name.isNotEmpty) {
      if (!mounted) return;

      try {
        print(
          'DEBUG: Creating session with name: $name, projectId: ${_project.id}',
        );

        // Utiliser le service dédié pour créer la session
        final createdSession = await createSessionForProject(
          projectId: _project.id,
          name: name,
        );

        print('DEBUG: Session created with id: ${createdSession.id}');

        if (!mounted) return;

        // Capture navigator before async operation
        final navigator = Navigator.of(context);

        final result = await navigator.push(
          MaterialPageRoute(
            builder: (context) =>
                SessionCompletionPage(session: createdSession),
          ),
        );

        print(
          'DEBUG: Returned from SessionCompletionPage with result: $result',
        );

        // Refresh sessions list
        _refreshSessions();

        // Optionally reload project data here if needed
      } catch (e) {
        print('DEBUG: Error creating session: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la création de la session: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
            onSelected: (value) {
              if (value == 'Editer') {
                _showRenameDialog();
              } else if (value == 'Supprimer') {
                _showDeleteConfirmationDialog();
              } else if (value == 'Exporter') {
                _showExportPage();
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
      body: BlocListener<ProjectBloc, ProjectState>(
        listener: (context, state) {
          // ...existing code...
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProjectInfoCard(
                project: _project,
                formatDuration: _formatDuration,
                formatDate: _formatDate,
              ),
              const SizedBox(height: 16),
              // Sessions section
              SessionsHeader(onAddSession: _showAddSessionDialog),
              const SizedBox(height: 8),
              Expanded(
                child: FutureBuilder<List<Session>>(
                  future: _sessionsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Erreur: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    }
                    final sessions = snapshot.data ?? [];
                    return ProjectSessionsList(
                      sessions: sessions,
                      formatDuration: _formatDuration,
                      onSessionTap: (session) async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                SessionIndexPage(session: session),
                          ),
                        );
                        if (result == true) {
                          _refreshSessions();
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Format date to readable string
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
