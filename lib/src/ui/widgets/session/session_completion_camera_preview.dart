import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class SessionCompletionCameraPreview extends StatelessWidget {
  final CameraController? cameraController;
  final bool isRecording;
  final VoidCallback onAction;

  const SessionCompletionCameraPreview({
    Key? key,
    required this.cameraController,
    required this.isRecording,
    required this.onAction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        cameraController != null && cameraController!.value.isInitialized
            ? CameraPreview(cameraController!)
            : Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Center(child: Text('No Camera Available')),
              ),
        Positioned(
          bottom: 16.0,
          left: 16.0,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(120, 50)),
            onPressed: onAction,
            child: Text(isRecording ? 'Stop' : 'Go!'),
          ),
        ),
      ],
    );
  }
}
