import 'package:flutter/material.dart';
import 'package:roadmindphone/features/project/domain/entities/project_entity.dart';
import 'package:roadmindphone/src/ui/widgets/project/project_card.dart';

class ProjectsList extends StatelessWidget {
  final List<ProjectEntity> projects;
  final void Function(ProjectEntity project)? onProjectTap;
  final String? emptyMessage;
  final String? error;
  final bool isLoading;
  final VoidCallback? onRetry;

  const ProjectsList({
    Key? key,
    required this.projects,
    this.onProjectTap,
    this.emptyMessage,
    this.error,
    this.isLoading = false,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error!, style: const TextStyle(color: Colors.red)),
            if (onRetry != null)
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
          ],
        ),
      );
    }
    if (projects.isEmpty) {
      return Center(child: Text(emptyMessage ?? 'Aucun projet trouvé.'));
    }
    return ListView.builder(
      itemCount: projects.length,
      itemBuilder: (context, index) {
        final project = projects[index];
        return ProjectCard(
          project: project,
          onTap: onProjectTap != null ? () => onProjectTap!(project) : null,
        );
      },
    );
  }
}
