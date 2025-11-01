import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart';

class FakePermissionHandlerPlatform extends PermissionHandlerPlatform {
  @override
  Future<PermissionStatus> checkPermissionStatus(Permission permission) {
    return Future.value(PermissionStatus.granted);
  }

  @override
  Future<Map<Permission, PermissionStatus>> requestPermissions(
    List<Permission> permissions,
  ) {
    return Future.value({
      for (var permission in permissions) permission: PermissionStatus.granted,
    });
  }

  @override
  Future<ServiceStatus> checkServiceStatus(Permission permission) {
    return Future.value(ServiceStatus.enabled);
  }

  @override
  Future<bool> shouldShowRequestPermissionRationale(Permission permission) {
    return Future.value(false);
  }

  @override
  Future<bool> openAppSettings() {
    return Future.value(true);
  }
}
