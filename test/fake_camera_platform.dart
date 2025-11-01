import 'dart:async';

import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class FakeCameraPlatform extends CameraPlatform {
  @override
  Future<List<CameraDescription>> availableCameras() async {
    return [
      const CameraDescription(
        name: 'camera',
        lensDirection: CameraLensDirection.back,
        sensorOrientation: 90,
      ),
    ];
  }

  @override
  Future<int> createCamera(
    CameraDescription cameraDescription,
    ResolutionPreset? resolutionPreset, {
    bool enableAudio = false,
  }) async {
    return 1;
  }

  @override
  Future<void> initializeCamera(
    int cameraId, {
    ImageFormatGroup? imageFormatGroup,
  }) async {
    return;
  }

  @override
  Future<void> startVideoRecording(
    int cameraId, {
    Duration? maxVideoDuration,
  }) async {
    return;
  }

  @override
  Future<XFile> stopVideoRecording(int cameraId) async {
    return XFile('/mock/video/path.mp4');
  }

  @override
  Future<void> dispose(int cameraId) {
    return Future.value();
  }

  @override
  Future<void> pauseVideoRecording(int cameraId) {
    return Future.value();
  }

  @override
  Future<void> resumeVideoRecording(int cameraId) {
    return Future.value();
  }

  Future<void> stopImageStream(int cameraId) {
    return Future.value();
  }

  @override
  Future<XFile> takePicture(int cameraId) {
    return Future.value(XFile('/mock/image/path.png'));
  }

  @override
  Future<void> setFlashMode(int cameraId, FlashMode mode) {
    return Future.value();
  }

  @override
  Future<void> setExposureMode(int cameraId, ExposureMode mode) {
    return Future.value();
  }

  @override
  Future<void> setFocusMode(int cameraId, FocusMode mode) {
    return Future.value();
  }

  @override
  Future<void> setZoomLevel(int cameraId, double zoom) {
    return Future.value();
  }

  Stream<CameraEvent> cameraEventStream(int cameraId) {
    return const Stream.empty();
  }

  @override
  Stream<DeviceOrientationChangedEvent> onDeviceOrientationChanged() {
    return const Stream.empty();
  }

  @override
  Stream<CameraInitializedEvent> onCameraInitialized(int cameraId) {
    return Stream.value(
      CameraInitializedEvent(
        cameraId,
        1920.0,
        1080.0,
        ExposureMode.auto,
        true,
        FocusMode.auto,
        true,
      ),
    );
  }

  @override
  Widget buildPreview(int cameraId) {
    return Container();
  }

  @override
  Future<double> getMaxZoomLevel(int cameraId) {
    return Future.value(1.0);
  }

  @override
  Future<double> getMinZoomLevel(int cameraId) {
    return Future.value(1.0);
  }

  @override
  Future<void> lockCaptureOrientation(
    int cameraId,
    DeviceOrientation orientation,
  ) {
    return Future.value();
  }

  @override
  Future<void> unlockCaptureOrientation(int cameraId) {
    return Future.value();
  }

  @override
  Future<void> pausePreview(int cameraId) {
    return Future.value();
  }

  @override
  Future<void> resumePreview(int cameraId) {
    return Future.value();
  }

  @override
  Future<double> setExposureOffset(int cameraId, double offset) {
    return Future.value(0.0);
  }

  @override
  Future<double> getMinExposureOffset(int cameraId) {
    return Future.value(0.0);
  }

  @override
  Future<double> getMaxExposureOffset(int cameraId) {
    return Future.value(0.0);
  }

  @override
  Future<double> getExposureOffsetStepSize(int cameraId) {
    return Future.value(0.0);
  }
}
