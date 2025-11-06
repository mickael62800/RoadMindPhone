import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:roadmindphone/session_gps_point.dart';

class SessionCompletionMap extends StatelessWidget {
  final LatLng? currentLocation;
  final List<SessionGpsPoint> gpsData;
  final MapController? mapController;
  final Widget Function({
    Key? key,
    required MapOptions options,
    List<Widget>? children,
    MapController? mapController,
  })
  flutterMapBuilder;

  const SessionCompletionMap({
    Key? key,
    required this.currentLocation,
    required this.gpsData,
    required this.flutterMapBuilder,
    this.mapController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (currentLocation == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return flutterMapBuilder(
      mapController: mapController,
      options: MapOptions(
        initialCenter: currentLocation ?? const LatLng(50.42, 2.83),
        initialZoom: 18.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
        ),
        if (currentLocation != null)
          MarkerLayer(
            markers: [
              Marker(
                width: 80.0,
                height: 80.0,
                point: currentLocation!,
                child: const Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 40.0,
                ),
              ),
            ],
          ),
        if (gpsData.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: gpsData.map((p) => p.toLatLng()).toList(),
                strokeWidth: 4.0,
                color: Colors.blue,
              ),
            ],
          ),
      ],
    );
  }
}
