import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:roadmindphone/session_gps_point.dart';

class LocationInitResult {
  final LatLng? currentLocation;
  final List<SessionGpsPoint> gpsData;
  final String? error;

  LocationInitResult({this.currentLocation, required this.gpsData, this.error});
}

Future<LocationInitResult> initializeLocation({
  required String sessionId,
  List<SessionGpsPoint>? existingGpsData,
}) async {
  try {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationInitResult(
        gpsData: [],
        error: 'Location services are disabled.',
      );
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return LocationInitResult(
          gpsData: [],
          error: 'Location permissions are denied',
        );
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return LocationInitResult(
        gpsData: [],
        error: 'Location permissions are permanently denied.',
      );
    }

    Position position = await Geolocator.getCurrentPosition();
    final currentLocation = LatLng(position.latitude, position.longitude);

    List<SessionGpsPoint> gpsData;
    if (existingGpsData == null || existingGpsData.isEmpty) {
      gpsData = [
        SessionGpsPoint(
          sessionId: sessionId,
          latitude: position.latitude,
          longitude: position.longitude,
          speed: position.speed,
          heading: position.heading,
          timestamp: position.timestamp,
          videoTimestampMs: 0,
        ),
      ];
    } else {
      gpsData = List.from(existingGpsData);
    }

    return LocationInitResult(
      currentLocation: currentLocation,
      gpsData: gpsData,
    );
  } catch (e) {
    return LocationInitResult(gpsData: [], error: e.toString());
  }
}
