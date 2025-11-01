import 'package:camera/camera.dart';
import 'package:mockito/mockito.dart';

abstract class MockCameraController extends CameraController implements Mock {
  MockCameraController(
    super.description,
    super.resolutionPreset, {
    super.enableAudio = false,
  });
}
