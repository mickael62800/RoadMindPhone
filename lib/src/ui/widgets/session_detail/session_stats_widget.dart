import 'package:flutter/material.dart';
import 'package:roadmindphone/session.dart';
import 'package:roadmindphone/src/ui/molecules/molecules.dart';

/// Widget displaying session statistics (GPS points, duration, speed, distance)
class SessionStatsWidget extends StatelessWidget {
  final Session session;
  final double averageSpeed;
  final double totalDistance;

  const SessionStatsWidget({
    super.key,
    required this.session,
    required this.averageSpeed,
    required this.totalDistance,
  });

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: [
        InfoCard(title: 'Points GPS', value: session.gpsPoints.toString()),
        InfoCard(title: 'Durée', value: _formatDuration(session.duration)),
        InfoCard(
          title: 'Vitesse Moyenne',
          value: '${averageSpeed.toStringAsFixed(2)} km/h',
        ),
        InfoCard(
          title: 'Distance',
          value: '${totalDistance.toStringAsFixed(2)} km',
        ),
      ],
    );
  }
}
