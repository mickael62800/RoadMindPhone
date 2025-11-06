import 'package:flutter/material.dart';
import 'package:roadmindphone/session.dart';

class ProjectSessionsList extends StatelessWidget {
  final List<Session> sessions;
  final String Function(Duration) formatDuration;
  final void Function(Session) onSessionTap;

  const ProjectSessionsList({
    super.key,
    required this.sessions,
    required this.formatDuration,
    required this.onSessionTap,
  });

  @override
  Widget build(BuildContext context) {
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
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
          child: ListTile(
            leading: session.exported == true
                ? const Icon(Icons.cloud_done, color: Colors.green)
                : const Icon(Icons.cloud_upload, color: Colors.grey),
            title: Text(session.name),
            subtitle: Text(
              'Durée: ${formatDuration(session.duration)} | GPS: ${session.gpsPoints} points',
            ),
            trailing: session.videoPath != null
                ? const Icon(Icons.check_circle, color: Colors.green)
                : const Icon(Icons.warning, color: Colors.orange),
            onTap: () => onSessionTap(session),
          ),
        );
      },
    );
  }
}
