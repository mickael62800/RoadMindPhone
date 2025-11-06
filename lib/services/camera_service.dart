import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

class CameraInitResult {
  final CameraController? controller;
  final List<CameraDescription>? cameras;
  final String? error;

  CameraInitResult({this.controller, this.cameras, this.error});
}

Future<CameraInitResult> initializeCamera({
  CameraController? existingController,
  List<CameraDescription>? existingCameras,
  ResolutionPreset preset = ResolutionPreset.medium,
  bool enableAudio = false,
  BuildContext? context,
}) async {
  try {
    if (existingController != null && existingCameras != null) {
      if (existingController.value.isInitialized) {
        return CameraInitResult(
          controller: existingController,
          cameras: existingCameras,
        );
      }
    }

    var status = await Permission.microphone.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      return CameraInitResult(
        error: 'Microphone permission denied. Cannot record audio.',
      );
    }

    final cameras = await availableCameras();
    if (cameras.isNotEmpty) {
      final controller = CameraController(
        cameras[0],
        preset,
        enableAudio: enableAudio,
      );
      await controller.initialize();
      return CameraInitResult(controller: controller, cameras: cameras);
    } else {
      return CameraInitResult(error: 'No cameras available.');
    }
  } catch (e) {
    return CameraInitResult(error: e.toString());
  }
}
