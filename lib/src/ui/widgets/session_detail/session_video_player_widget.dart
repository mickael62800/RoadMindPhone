import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Widget displaying video player with play/pause controls
class SessionVideoPlayerWidget extends StatefulWidget {
  final VideoPlayerController? videoController;
  final Future<void>? initializeVideoPlayerFuture;
  final bool isLandscape;

  const SessionVideoPlayerWidget({
    super.key,
    required this.videoController,
    required this.initializeVideoPlayerFuture,
    this.isLandscape = false,
  });

  @override
  State<SessionVideoPlayerWidget> createState() =>
      _SessionVideoPlayerWidgetState();
}

class _SessionVideoPlayerWidgetState extends State<SessionVideoPlayerWidget> {
  @override
  Widget build(BuildContext context) {
    final videoContent = Container(
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.withAlpha((255 * 0.5).round()),
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6.0),
        child: widget.videoController != null
            ? FutureBuilder(
                future: widget.initializeVideoPlayerFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        AspectRatio(
                          aspectRatio:
                              widget.videoController!.value.aspectRatio,
                          child: VideoPlayer(widget.videoController!),
                        ),
                        IconButton(
                          icon: Icon(
                            widget.videoController!.value.isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                            color: Colors.white,
                            size: 50.0,
                          ),
                          onPressed: () {
                            setState(() {
                              widget.videoController!.value.isPlaying
                                  ? widget.videoController!.pause()
                                  : widget.videoController!.play();
                            });
                          },
                        ),
                      ],
                    );
                  } else if (snapshot.hasError) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 80.0,
                            color: Colors.red,
                          ),
                          SizedBox(height: 16.0),
                          Text('Erreur de chargement de la vidéo.'),
                        ],
                      ),
                    );
                  } else {
                    return const Center(child: CircularProgressIndicator());
                  }
                },
              )
            : const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.videocam_off, size: 80.0, color: Colors.grey),
                    SizedBox(height: 16.0),
                    Text('En attente de vidéo'),
                  ],
                ),
              ),
      ),
    );

    if (widget.isLandscape) {
      return Expanded(child: videoContent);
    }

    return SizedBox(height: 220, child: videoContent);
  }
}
