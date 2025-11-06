import 'package:roadmindphone/services/project_service/project_stats.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roadmindphone/features/project/presentation/bloc/bloc.dart';
import 'package:roadmindphone/features/project/domain/entities/project_entity.dart';
import 'package:roadmindphone/features/project/presentation/pages/project_detail_page.dart';
import 'package:roadmindphone/src/ui/organisms/organisms.dart';
import 'package:roadmindphone/settings_page.dart';
import 'package:roadmindphone/database_helper.dart';

/// Main page displaying the list of all projects
///
/// Uses ProjectBloc to manage state and handle user actions.
/// Follows Clean Architecture principles with BLoC pattern.
class ProjectListPage extends StatefulWidget {
  const ProjectListPage({super.key});

  @override
  State<ProjectListPage> createState() => _ProjectListPageState();
}

class _ProjectListPageState extends State<ProjectListPage> {
  // Affiche une boîte de dialogue pour ajouter un projet
  void _showAddProjectDialog() async {
    final TextEditingController controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Créer un projet'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Nom du projet'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Créer'),
          ),
        ],
      ),
    );
    if (result != null && result.trim().isNotEmpty) {
      context.read<ProjectBloc>().add(CreateProjectEvent(title: result.trim()));
    }
  }

  // Ajout d'un utilitaire pour formater la durée
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  int _totalGpsPoints = 0;
  int _totalVideos = 0;
  Map<String, bool> _projectWarnings = {};

  @override
  void initState() {
    super.initState();
    // Load projects when page is first displayed
    context.read<ProjectBloc>().add(const LoadProjectsEvent());
  }

  /// Load additional statistics (GPS points and videos count)
  Future<void> _loadAdditionalStats(List<ProjectEntity> projects) async {
    final stats = await computeProjectStats(projects);
    if (mounted) {
      setState(() {
        _totalGpsPoints = stats['gpsPoints'] as int;
        _totalVideos = stats['videos'] as int;
        _projectWarnings = stats['warnings'] as Map<String, bool>;
      });
    }
    // Ignore errors for stats
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Liste des Projets'),
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
      body: BlocConsumer<ProjectBloc, ProjectState>(
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
        builder: (context, state) {
          // Loading state
          if (state is ProjectsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Empty state
          if (state is ProjectsEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.folder_open, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'Aucun projet pour le moment.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _showAddProjectDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Créer un projet'),
                  ),
                ],
              ),
            );
          }

          // Error state
          if (state is ProjectError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur: ${state.message}',
                    style: const TextStyle(fontSize: 18, color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<ProjectBloc>().add(
                        const LoadProjectsEvent(),
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          // Loaded state
          List<ProjectEntity> projects = [];
          if (state is ProjectsLoaded) {
            projects = state.projects;
            // Load additional stats when projects are loaded
            _loadAdditionalStats(projects);
          }

          // Calculate statistics
          final int totalProjects = projects.length;
          final int totalSessions = projects.fold<int>(
            0,
            (sum, project) => sum + project.sessionCount,
          );
          final Duration totalDuration = projects.fold<Duration>(
            Duration.zero,
            (sum, project) => sum + project.duration,
          );
          return RefreshIndicator(
            onRefresh: () async {
              context.read<ProjectBloc>().add(const RefreshProjectsEvent());
              // Wait for the refresh to complete
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: Column(
              children: [
                // Statistics Card (same style as project detail page)
                if (projects.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Statistiques globales',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 16),
                              _buildInfoRow(
                                Icons.folder,
                                'Projets',
                                totalProjects.toString(),
                              ),
                              const SizedBox(height: 8),
                              _buildInfoRow(
                                Icons.videocam,
                                'Sessions',
                                totalSessions.toString(),
                              ),
                              const SizedBox(height: 8),
                              _buildInfoRow(
                                Icons.timer,
                                'Durée totale',
                                _formatDuration(totalDuration),
                              ),
                              const SizedBox(height: 8),
                              _buildInfoRow(
                                Icons.location_on,
                                'Points GPS',
                                _totalGpsPoints.toString(),
                              ),
                              const SizedBox(height: 8),
                              _buildInfoRow(
                                Icons.video_library,
                                'Vidéos',
                                _totalVideos.toString(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                // Projects section header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Projets',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      ElevatedButton.icon(
                        onPressed: _showAddProjectDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Nouveau projet'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Projects List
                Expanded(
                  child: ItemsListView<ProjectEntity>(
                    items: projects,
                    titleBuilder: (project) => project.title,
                    subtitleBuilder: (project) =>
                        'Sessions: ${project.sessionCount} | Durée: ${_formatDuration(project.duration)}',
                    trailingBuilder: (project) {
                      // Show warning icon if project has incomplete sessions
                      if (_projectWarnings[project.id] == true) {
                        return const Icon(
                          Icons.warning,
                          color: Colors.orange,
                          size: 28,
                        );
                      }
                      return null;
                    },
                    onTapBuilder: (project) async {
                      if (!mounted) return;

                      // Capture context before async operation
                      final navigator = Navigator.of(context);
                      final projectBloc = context.read<ProjectBloc>();

                      // Navigate to project details page
                      await navigator.push<bool>(
                        MaterialPageRoute(
                          builder: (context) => BlocProvider.value(
                            value: projectBloc,
                            child: ProjectDetailPage(project: project),
                          ),
                        ),
                      );

                      // Always reload projects when returning from detail page
                      // This ensures the list is refreshed with updated session counts and durations
                      if (mounted) {
                        projectBloc.add(const LoadProjectsEvent());
                      }
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
