import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:camera/camera.dart';
import 'package:roadmindphone/session_gps_point.dart';
import 'package:roadmindphone/src/ui/widgets/session/session_completion_map.dart';
import 'package:roadmindphone/src/ui/widgets/session/session_completion_camera_preview.dart';

typedef FlutterMapBuilder =
    Widget Function({
      Key? key,
      required MapOptions options,
      List<Widget>? children,
      MapController? mapController,
    });

class SessionCompletionLayout extends StatelessWidget {
  final bool isLandscape;
  final LatLng? currentLocation;
  final List<SessionGpsPoint> gpsData;
  final CameraController? cameraController;
  final bool isRecording;
  final VoidCallback onAction;
  final FlutterMapBuilder flutterMapBuilder;
  final MapController? mapController;

  const SessionCompletionLayout({
    Key? key,
    required this.isLandscape,
    required this.currentLocation,
    required this.gpsData,
    required this.cameraController,
    required this.isRecording,
    required this.onAction,
    required this.flutterMapBuilder,
    this.mapController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLandscape) {
      return Row(
        key: const Key('landscape_layout'),
        children: <Widget>[
          Expanded(
            flex: 1,
            child: SessionCompletionMap(
              currentLocation: currentLocation,
              gpsData: gpsData,
              flutterMapBuilder: flutterMapBuilder,
              mapController: mapController,
            ),
          ),
          Expanded(
            flex: 1,
            child: SessionCompletionCameraPreview(
              cameraController: cameraController,
              isRecording: isRecording,
              onAction: onAction,
            ),
          ),
        ],
      );
    } else {
      return Column(
        key: const Key('portrait_layout'),
        children: <Widget>[
          Expanded(
            flex: 1,
            child: SessionCompletionMap(
              currentLocation: currentLocation,
              gpsData: gpsData,
              flutterMapBuilder: flutterMapBuilder,
              mapController: mapController,
            ),
          ),
          Expanded(
            flex: 2,
            child: SessionCompletionCameraPreview(
              cameraController: cameraController,
              isRecording: isRecording,
              onAction: onAction,
            ),
          ),
        ],
      );
    }
  }
}
