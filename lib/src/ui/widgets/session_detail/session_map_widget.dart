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
class SessionMapWidget extends StatefulWidget {
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
  State<SessionMapWidget> createState() => _SessionMapWidgetState();
}

class _SessionMapWidgetState extends State<SessionMapWidget> {
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _centerMapOnGpsPoint();
  }

  @override
  void didUpdateWidget(SessionMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recentrer la carte si la session change
    if (oldWidget.session.id != widget.session.id) {
      _centerMapOnGpsPoint();
    }
  }

  void _centerMapOnGpsPoint() {
    if (widget.session.gpsData.isNotEmpty) {
      // Utiliser addPostFrameCallback pour être sûr que la carte est construite
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          final targetPoint = LatLng(
            widget.session.gpsData.first.latitude,
            widget.session.gpsData.first.longitude,
          );

          // Centrer la carte
          _mapController.move(targetPoint, 18.0);

          // Forcer un léger mouvement pour déclencher le chargement des tuiles
          Future.delayed(const Duration(milliseconds: 100), () {
            try {
              _mapController.move(
                LatLng(targetPoint.latitude + 0.00001, targetPoint.longitude),
                18.0,
              );
              Future.delayed(const Duration(milliseconds: 50), () {
                try {
                  _mapController.move(targetPoint, 18.0);
                } catch (e) {
                  debugPrint('DEBUG: Error moving map (final): $e');
                }
              });
            } catch (e) {
              debugPrint('DEBUG: Error moving map (micro): $e');
            }
          });
        } catch (e) {
          debugPrint('DEBUG: Error centering map: $e');
        }
      });
    }
  }

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
        child: widget.session.gpsData.isNotEmpty
            ? widget.mapBuilder(
                mapController: _mapController, // Passer le controller
                options: MapOptions(
                  initialCenter: LatLng(
                    widget.session.gpsData.first.latitude,
                    widget.session.gpsData.first.longitude,
                  ),
                  initialZoom: 18.0, // Zoom plus proche pour mieux voir
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  ),
                  // Ajouter un marqueur pour le point GPS
                  if (widget.session.gpsData.isNotEmpty)
                    MarkerLayer(
                      markers: [
                        Marker(
                          width: 80.0,
                          height: 80.0,
                          point: LatLng(
                            widget.session.gpsData.first.latitude,
                            widget.session.gpsData.first.longitude,
                          ),
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 40.0,
                          ),
                        ),
                      ],
                    ),
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: widget.session.gpsData
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

    if (widget.isLandscape) {
      return Expanded(child: mapContent);
    }

    return SizedBox(height: 220, child: mapContent);
  }
}
