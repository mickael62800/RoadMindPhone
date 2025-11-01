import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  debugPrint('Permission.microphone.value: ${Permission.microphone.value}');
  debugPrint(
    'PermissionStatus.granted.index: ${PermissionStatus.granted.index}',
  );
}
