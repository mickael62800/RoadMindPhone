import 'dart:async';

import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';

class FakeGeolocatorPlatform extends GeolocatorPlatform {
  bool _serviceEnabled = true;
  LocationPermission _permission = LocationPermission.whileInUse;
  Position _currentPosition = Position(
    latitude: 48.8566,
    longitude: 2.3522,
    timestamp: DateTime.now(),
    accuracy: 0.0,
    altitude: 0.0,
    heading: 0.0,
    speed: 0.0,
    speedAccuracy: 0.0,
    altitudeAccuracy: 0.0,
    headingAccuracy: 0.0,
  );

  final _positionStreamController = StreamController<Position>();

  void setMockLocationServiceEnabled(bool enabled) {
    _serviceEnabled = enabled;
  }

  void setMockPermission(LocationPermission permission) {
    _permission = permission;
  }

  void setMockPosition(Position position) {
    _currentPosition = position;
  }

  void addPosition(Position position) {
    _positionStreamController.add(position);
  }

  void pushPositionUpdate(Position position) {
    _positionStreamController.add(position);
  }

  @override
  Future<LocationPermission> checkPermission() async {
    return _permission;
  }

  @override
  Future<LocationPermission> requestPermission() async {
    return _permission;
  }

  @override
  Future<bool> isLocationServiceEnabled() async {
    return _serviceEnabled;
  }

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    return _currentPosition;
  }

  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) {
    return _positionStreamController.stream;
  }

  Future<ServiceStatus> getLocationServiceStatus() {
    return Future.value(ServiceStatus.enabled);
  }

  @override
  Future<bool> openAppSettings() {
    return Future.value(true);
  }

  @override
  Future<bool> openLocationSettings() {
    return Future.value(true);
  }

  Future<double?> getAccuracy() {
    return Future.value(0.0);
  }

  @override
  Future<LocationAccuracyStatus> requestTemporaryFullAccuracy({
    required String purposeKey,
  }) {
    return Future.value(LocationAccuracyStatus.reduced);
  }

  Future<bool> openAppSettingsIfNecessary() {
    return Future.value(true);
  }

  Future<bool> openLocationSettingsIfNecessary() {
    return Future.value(true);
  }
}
