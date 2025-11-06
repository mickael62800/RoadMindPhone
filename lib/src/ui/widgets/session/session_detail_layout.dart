import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/material.dart';
import 'package:roadmindphone/src/ui/widgets/session_detail/session_stats_widget.dart';
import 'package:roadmindphone/src/ui/widgets/session_detail/session_map_widget.dart';
import 'package:roadmindphone/src/ui/widgets/session_detail/session_video_player_widget.dart';
import 'package:roadmindphone/session.dart';
import 'package:video_player/video_player.dart';

class SessionDetailLayout extends StatelessWidget {
  final Session session;
  final double averageSpeed;
  final double totalDistance;
  final VideoPlayerController? videoController;
  final Future<void>? initializeVideoPlayerFuture;
  final bool isLandscape;
  final Widget Function({
    Key? key,
    required MapOptions options,
    List<Widget>? children,
    MapController? mapController,
  })
  flutterMapBuilder;

  const SessionDetailLayout({
    super.key,
    required this.session,
    required this.averageSpeed,
    required this.totalDistance,
    required this.videoController,
    required this.initializeVideoPlayerFuture,
    required this.isLandscape,
    required this.flutterMapBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final statsWidget = SessionStatsWidget(
      session: session,
      averageSpeed: averageSpeed,
      totalDistance: totalDistance,
    );
    final mapWidget = SessionMapWidget(
      key: ValueKey('map_${session.id}_${session.gpsData.length}'),
      session: session,
      mapBuilder: flutterMapBuilder,
      isLandscape: isLandscape,
    );
    final videoWidget = SessionVideoPlayerWidget(
      videoController: videoController,
      initializeVideoPlayerFuture: initializeVideoPlayerFuture,
      isLandscape: isLandscape,
    );
    if (isLandscape) {
      return Column(
        children: [
          SizedBox(
            height: 120,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 8.0,
              ),
              child: statsWidget,
            ),
          ),
          Expanded(flex: 4, child: Row(children: [mapWidget, videoWidget])),
        ],
      );
    } else {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16.0),
            statsWidget,
            const SizedBox(height: 16.0),
            mapWidget,
            const SizedBox(height: 16.0),
            videoWidget,
            const SizedBox(height: 16.0),
          ],
        ),
      );
    }
  }
}
