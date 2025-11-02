import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roadmindphone/features/project/presentation/bloc/bloc.dart';
import 'package:roadmindphone/features/project/domain/entities/project_entity.dart';
import 'package:roadmindphone/features/project/presentation/pages/project_detail_page.dart';
import 'package:roadmindphone/src/ui/organisms/organisms.dart';
import 'package:roadmindphone/settings_page.dart';

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
  @override
  void initState() {
    super.initState();
    // Load projects when page is first displayed
    context.read<ProjectBloc>().add(const LoadProjectsEvent());
  }

  /// Format duration to HH:MM:SS
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
  }

  /// Show dialog to add a new project
  void _showAddProjectDialog() async {
    final String? title = await showAddItemDialog(
      context: context,
      title: 'Nouveau Projet',
      hintText: 'Titre du projet',
    );

    if (title != null && title.isNotEmpty) {
      if (!mounted) return;
      context.read<ProjectBloc>().add(CreateProjectEvent(title: title));
    }
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
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<ProjectBloc>().add(const RefreshProjectsEvent());
              // Wait for the refresh to complete
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: ItemsListView<ProjectEntity>(
              items: projects,
              titleBuilder: (project) => project.title,
              subtitleBuilder: (project) =>
                  'Sessions: ${project.sessionCount} | Durée: ${_formatDuration(project.duration)}',
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
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProjectDialog,
        tooltip: 'Ajouter un projet',
        child: const Icon(Icons.add),
      ),
    );
  }
}
