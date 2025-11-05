import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roadmindphone/features/project/presentation/bloc/bloc.dart';
import 'package:roadmindphone/features/project/domain/entities/project_entity.dart';
import 'package:roadmindphone/src/ui/molecules/molecules.dart';
import 'package:roadmindphone/database_helper.dart';
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
  bool _isRefreshingProject = false;

  @override
  void initState() {
    super.initState();
    _project = widget.project;
    _refreshSessions();
  }

  /// Refresh the sessions list and reload project data
  void _refreshSessions() {
    setState(() {
      _sessionsFuture = DatabaseHelper.instance.readAllSessionsForProject(
        _project.id!,
      );
      _isRefreshingProject = true;
    });

    // Reload project data to update session count and duration
    context.read<ProjectBloc>().add(GetProjectEvent(projectId: _project.id!));
  }

  /// Update project data when bloc state changes
  void _handleProjectLoaded(ProjectEntity project) {
    if (_isRefreshingProject && mounted) {
      setState(() {
        _project = project;
        _isRefreshingProject = false;
      });
    }
  }

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

      projectBloc.add(DeleteProjectEvent(projectId: _project.id!));

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
      // Get sessions from DatabaseHelper for export
      final sessions = await DatabaseHelper.instance.readAllSessionsForProject(
        _project.id!,
      );

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

        // Create session via DatabaseHelper for immediate result
        final createdSession = await DatabaseHelper.instance.createSession(
          Session(
            projectId: _project.id!,
            name: name,
            duration: const Duration(),
            gpsPoints: 0,
          ),
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
          // Update project when loaded after refresh
          if (state is ProjectLoaded) {
            _handleProjectLoaded(state.project);
          }
          // Show snackbar for operation success
          if (state is ProjectOperationSuccess) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
          // Show snackbar for errors
          if (state is ProjectError) {
            if (_isRefreshingProject) {
              setState(() {
                _isRefreshingProject = false;
              });
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Project Info Card
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Informations du projet',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(Icons.folder, 'Titre', _project.title),
                      if (_project.description != null) ...[
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          Icons.description,
                          'Description',
                          _project.description!,
                        ),
                      ],
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        Icons.event_note,
                        'Sessions',
                        '${_project.sessionCount}',
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        Icons.timer,
                        'Durée totale',
                        _formatDuration(_project.duration),
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        Icons.calendar_today,
                        'Créé le',
                        _formatDate(_project.createdAt),
                      ),
                      if (_project.updatedAt != null) ...[
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          Icons.update,
                          'Modifié le',
                          _formatDate(_project.updatedAt!),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Sessions section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sessions',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  ElevatedButton.icon(
                    onPressed: _showAddSessionDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Nouvelle session'),
                  ),
                ],
              ),
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

                    if (sessions.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'Aucune session pour le moment.',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: sessions.length,
                      itemBuilder: (context, index) {
                        final session = sessions[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 0,
                          ),
                          child: ListTile(
                            leading: session.exported == true
                                ? const Icon(
                                    Icons.cloud_done,
                                    color: Colors.green,
                                  )
                                : const Icon(
                                    Icons.cloud_upload,
                                    color: Colors.grey,
                                  ),
                            title: Text(session.name),
                            subtitle: Text(
                              'Durée: ${_formatDuration(session.duration)} | GPS: ${session.gpsPoints} points',
                            ),
                            trailing: session.videoPath != null
                                ? const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  )
                                : const Icon(
                                    Icons.warning,
                                    color: Colors.orange,
                                  ),
                            onTap: () async {
                              // Navigate to session detail page
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      SessionIndexPage(session: session),
                                ),
                              );

                              // Refresh sessions list if session was modified or deleted
                              if (result == true) {
                                _refreshSessions();
                              }
                            },
                          ),
                        );
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

  /// Build an info row with icon, label and value
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
        Expanded(child: Text(value, overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  /// Format date to readable string
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
