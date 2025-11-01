import 'package:mockito/annotations.dart';
import 'package:http/http.dart';
import 'package:roadmindphone/database_helper.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:roadmindphone/session.dart'; // Corrected import for Session
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

@GenerateMocks([
  Client,
  DatabaseHelper,
  GeolocatorPlatform,
  CameraPlatform,
  SharedPreferences,
  Session,
  CameraController,
  CameraValue,
  Permission,
])
void main() {}
