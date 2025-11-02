import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roadmindphone/features/project/presentation/bloc/bloc.dart';
import 'package:roadmindphone/features/project/domain/entities/project_entity.dart';
import 'package:roadmindphone/src/ui/molecules/molecules.dart';

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

  @override
  void initState() {
    super.initState();
    _project = widget.project;
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
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Supprimer le projet',
      content:
          'Êtes-vous sûr de vouloir supprimer ce projet ? Cette action est irréversible.',
      confirmText: 'SUPPRIMER',
    );

    if (confirmed == true) {
      if (!mounted) return;

      context.read<ProjectBloc>().add(
        DeleteProjectEvent(projectId: _project.id!),
      );

      // Return to previous screen after a short delay
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      Navigator.of(context).pop(true); // Return true to indicate deletion
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
                // TODO: Implement export functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Fonction d\'exportation à venir'),
                  ),
                );
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
          // Show snackbar for operation success
          if (state is ProjectOperationSuccess) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
          // Show snackbar for errors
          if (state is ProjectError) {
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
              Text('Sessions', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.video_collection,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Aucune session pour le moment.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          // TODO: Navigate to create session page
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Création de session à venir'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Créer une session'),
                      ),
                    ],
                  ),
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
