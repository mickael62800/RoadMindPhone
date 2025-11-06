import 'package:flutter/material.dart';
import 'package:roadmindphone/session.dart';

class SessionsList extends StatelessWidget {
  final List<Session> sessions;
  final void Function(Session session)? onSessionTap;
  final String? emptyMessage;
  final String? error;
  final bool isLoading;
  final VoidCallback? onRetry;
  final String Function(Duration duration)? formatDuration;

  const SessionsList({
    Key? key,
    required this.sessions,
    this.onSessionTap,
    this.emptyMessage,
    this.error,
    this.isLoading = false,
    this.onRetry,
    this.formatDuration,
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
    if (sessions.isEmpty) {
      return Center(child: Text(emptyMessage ?? 'Aucune session trouvée.'));
    }
    return ListView.builder(
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final session = sessions[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: ListTile(
            onTap: onSessionTap != null ? () => onSessionTap!(session) : null,
            title: Text(session.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (session.notes != null && session.notes!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(session.notes!),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        formatDuration != null
                            ? formatDuration!(session.duration)
                            : _formatDuration(session.duration),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            trailing: session.exported == true
                ? const Icon(Icons.check_circle, color: Colors.green)
                : null,
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
  }
}
