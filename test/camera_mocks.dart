import 'package:camera/camera.dart';
import 'package:mockito/mockito.dart';

// A dummy CameraDescription for the MockableCameraController
final CameraDescription _dummyCameraDescription = CameraDescription(
  name: 'MockCamera',
  lensDirection: CameraLensDirection.back,
  sensorOrientation: 90,
);

abstract class MockableCameraController extends CameraController implements Mock {
  // Provide a concrete constructor that calls the superclass constructor
  MockableCameraController() : super(_dummyCameraDescription, ResolutionPreset.medium);
}
