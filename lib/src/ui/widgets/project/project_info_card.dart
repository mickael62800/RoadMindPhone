import 'package:flutter/material.dart';
import 'package:roadmindphone/features/project/domain/entities/project_entity.dart';

class ProjectInfoCard extends StatelessWidget {
  final ProjectEntity project;
  final String Function(Duration) formatDuration;
  final String Function(DateTime) formatDate;

  const ProjectInfoCard({
    super.key,
    required this.project,
    required this.formatDuration,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
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
            _buildInfoRow(Icons.folder, 'Titre', project.title),
            if (project.description != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.description,
                'Description',
                project.description!,
              ),
            ],
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.event_note,
              'Sessions',
              '${project.sessionCount}',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.timer,
              'Durée totale',
              formatDuration(project.duration),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.calendar_today,
              'Créé le',
              formatDate(project.createdAt),
            ),
            if (project.updatedAt != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.update,
                'Modifié le',
                formatDate(project.updatedAt!),
              ),
            ],
          ],
        ),
      ),
    );
  }

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
}
