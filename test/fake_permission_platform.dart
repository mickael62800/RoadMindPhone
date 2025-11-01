import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart';

class FakePermissionPlatform extends PermissionHandlerPlatform {
  PermissionStatus _microphonePermissionStatus = PermissionStatus.granted;

  void setMicrophonePermissionStatus(PermissionStatus status) {
    _microphonePermissionStatus = status;
  }

  @override
  Future<PermissionStatus> checkPermissionStatus(Permission permission) async {
    if (permission == Permission.microphone) {
      return _microphonePermissionStatus;
    }
    return PermissionStatus.granted;
  }

  @override
  Future<Map<Permission, PermissionStatus>> requestPermissions(
    List<Permission> permissions,
  ) async {
    final Map<Permission, PermissionStatus> statuses = {};
    for (final permission in permissions) {
      if (permission == Permission.microphone) {
        statuses[permission] = _microphonePermissionStatus;
      } else {
        statuses[permission] = PermissionStatus.granted;
      }
    }
    return statuses;
  }

  @override
  Future<bool> openAppSettings() {
    return Future.value(true);
  }

  @override
  Future<ServiceStatus> checkServiceStatus(Permission permission) {
    return Future.value(ServiceStatus.enabled);
  }

  @override
  Future<bool> shouldShowRequestPermissionRationale(Permission permission) {
    return Future.value(false);
  }
}
