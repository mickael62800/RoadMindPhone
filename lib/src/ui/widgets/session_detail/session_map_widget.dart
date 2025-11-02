import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:roadmindphone/session.dart';

typedef FlutterMapBuilder =
    Widget Function({
      Key? key,
      required MapOptions options,
      List<Widget>? children,
      MapController? mapController,
    });

/// Widget displaying GPS map with session route
class SessionMapWidget extends StatelessWidget {
  final Session session;
  final FlutterMapBuilder mapBuilder;
  final bool isLandscape;

  const SessionMapWidget({
    super.key,
    required this.session,
    required this.mapBuilder,
    this.isLandscape = false,
  });

  @override
  Widget build(BuildContext context) {
    final mapContent = Container(
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.withAlpha((255 * 0.5).round()),
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6.0),
        child: session.gpsData.isNotEmpty
            ? mapBuilder(
                options: MapOptions(
                  initialCenter: LatLng(
                    session.gpsData.first.latitude,
                    session.gpsData.first.longitude,
                  ),
                  initialZoom: 13.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  ),
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: session.gpsData
                            .map((p) => LatLng(p.latitude, p.longitude))
                            .toList(),
                        strokeWidth: 4.0,
                        color: Colors.blue,
                      ),
                    ],
                  ),
                ],
              )
            : const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map, size: 80.0, color: Colors.grey),
                    SizedBox(height: 16.0),
                    Text('En attente de données'),
                  ],
                ),
              ),
      ),
    );

    if (isLandscape) {
      return Expanded(child: mapContent);
    }

    return SizedBox(height: 220, child: mapContent);
  }
}
