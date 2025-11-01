import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:roadmindphone/database_helper.dart';
import 'package:roadmindphone/session.dart'; // Import Session class
import 'package:roadmindphone/session_completion_page.dart';

typedef FlutterMapBuilder =
    Widget Function({
      Key? key,
      required MapOptions options,
      List<Widget>? children,
      MapController? mapController,
    });

class SessionIndexPage extends StatefulWidget {
  final Session session;
  final FlutterMapBuilder flutterMapBuilder;

  const SessionIndexPage({
    super.key,
    required this.session,
    this.flutterMapBuilder = _defaultFlutterMapBuilder,
  });

  static Widget _defaultFlutterMapBuilder({
    Key? key,
    required MapOptions options,
    List<Widget>? children = const [],
    MapController? mapController,
  }) {
    return FlutterMap(
      key: key,
      mapController: mapController,
      children: children ?? [],
    );
  }

  @override
  State<SessionIndexPage> createState() => _SessionIndexPageState();
}

class _SessionIndexPageState extends State<SessionIndexPage> {
  late Session _session;
  double _totalDistance = 0.0;
  double _averageSpeed = 0.0;
  VideoPlayerController? _videoController;
  late Future<void> _initializeVideoPlayerFuture;

  @override
  void initState() {
    super.initState();
    _session = widget.session; // Initialize _session with the passed session
    _refreshSession();
  }

  Future<void> _refreshSession() async {
    final updatedSession = await DatabaseHelper.instance.readSession(
      _session.id!,
    ); // Use _session.id! here
    setState(() {
      _session = updatedSession; // Update _session
      _calculateSessionData(); // Call after _session is updated
    });
    _determinePosition();
    if (_session.videoPath != null && File(_session.videoPath!).existsSync()) {
      _videoController = VideoPlayerController.file(File(_session.videoPath!));
      _initializeVideoPlayerFuture = _videoController!.initialize();
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    await Geolocator.getCurrentPosition();
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a =
        0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  void _calculateSessionData() {
    if (_session.gpsData.length > 1) {
      double totalDistance = 0;
      double totalSpeed = 0;

      for (int i = 0; i < _session.gpsData.length - 1; i++) {
        final point1 = _session.gpsData[i];
        final point2 = _session.gpsData[i + 1];
        totalDistance += _calculateDistance(
          point1.latitude,
          point1.longitude,
          point2.latitude,
          point2.longitude,
        );
      }

      for (final point in _session.gpsData) {
        totalSpeed += point.speed ?? 0.0;
      }

      setState(() {
        _totalDistance = totalDistance;
        _averageSpeed = _session.gpsData.isNotEmpty
            ? totalSpeed /
                  _session.gpsData.length *
                  3.6 // convert m/s to km/h
            : 0.0;
      });
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_session.name),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: <Widget>[
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'Editer') {
                _showRenameDialog();
              } else if (value == 'Supprimer') {
                _showDeleteConfirmationDialog();
              } else if (value == 'Refaire') {
                _showRedoConfirmationDialog();
              } else if (value == 'Exporter') {
                _exportSessionData();
              } else {
                debugPrint('Value: $value');
              }
            },
            itemBuilder: (BuildContext context) {
              return {'Editer', 'Supprimer', 'Refaire', 'Exporter'}.map((
                String choice,
              ) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(choice),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: OrientationBuilder(
        builder: (context, orientation) {
          final isLandscape = orientation == Orientation.landscape;
          final children = [
            _buildInfoCard('Points GPS', _session.gpsPoints.toString()),
            _buildInfoCard('Durée', _formatDuration(_session.duration)),
            _buildInfoCard(
              'Vitesse Moyenne',
              '${_averageSpeed.toStringAsFixed(2)} km/h',
            ),
            _buildInfoCard(
              'Distance',
              '${_totalDistance.toStringAsFixed(2)} km',
            ),
          ];

          final mapWidget = Expanded(
            child: Container(
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
                child: _session.gpsData.isNotEmpty
                    ? widget.flutterMapBuilder(
                        options: MapOptions(
                          initialCenter: LatLng(
                            _session.gpsData.first.latitude,
                            _session.gpsData.first.longitude,
                          ),
                          initialZoom: 13.0,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                            subdomains: const ['a', 'b', 'c'],
                          ),
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: _session.gpsData
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
            ),
          );

          final videoWidget = Expanded(
            child: Container(
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
                child: _videoController != null
                    ? FutureBuilder(
                        future: _initializeVideoPlayerFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.done) {
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                AspectRatio(
                                  aspectRatio:
                                      _videoController!.value.aspectRatio,
                                  child: VideoPlayer(_videoController!),
                                ),
                                IconButton(
                                  icon: Icon(
                                    _videoController!.value.isPlaying
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                    color: Colors.white,
                                    size: 50.0,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _videoController!.value.isPlaying
                                          ? _videoController!.pause()
                                          : _videoController!.play();
                                    });
                                  },
                                ),
                              ],
                            );
                          } else if (snapshot.hasError) {
                            return const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    size: 80.0,
                                    color: Colors.red,
                                  ),
                                  SizedBox(height: 16.0),
                                  Text('Erreur de chargement de la vidéo.'),
                                ],
                              ),
                            );
                          } else {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                        },
                      )
                    : const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.videocam_off,
                              size: 80.0,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16.0),
                            Text('En attente de vidéo'),
                          ],
                        ),
                      ),
              ),
            ),
          );

          if (isLandscape) {
            return Column(
              children: [
                SizedBox(
                  height: 120,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 8.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: children
                          .map((card) => SizedBox(width: 180, child: card))
                          .toList(),
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Row(children: [mapWidget, videoWidget]),
                ),
              ],
            );
          } else {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [children[0], children[1]],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [children[2], children[3]],
                  ),
                ),
                mapWidget,
                videoWidget,
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildInfoCard(String title, String value) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Supprimer la session'),
          content: const Text(
            'Êtes-vous sûr de vouloir supprimer cette session ?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('ANNULER'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('SUPPRIMER'),
              onPressed: () async {
                await DatabaseHelper.instance.deleteSession(_session.id!);
                if (!context.mounted) return;
                Navigator.of(context).pop(); // Close the dialog
                Navigator.of(context).pop(); // Go back to the previous screen
              },
            ),
          ],
        );
      },
    );
  }

  void _showRenameDialog() async {
    final TextEditingController controller = TextEditingController(
      text: _session.name,
    );

    final newName = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Renommer la session'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: "Nouveau nom de la session",
            ),
            onSubmitted: (value) {
              Navigator.of(dialogContext).pop(value);
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('ANNULER'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('RENOMMER'),
              onPressed: () {
                Navigator.of(dialogContext).pop(controller.text);
              },
            ),
          ],
        );
      },
    );

    if (newName != null && newName.isNotEmpty) {
      final updatedSession = _session.copy(name: newName);
      await DatabaseHelper.instance.updateSession(updatedSession);
      if (!mounted) return;
      setState(() {
        _session = updatedSession;
      });
    }
  }

  void _showRedoConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Refaire la session'),
          content: const Text(
            'Êtes-vous sûr de vouloir refaire cette session ? La vidéo et les données GPS seront supprimées.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('ANNULER'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('CONFIRMER'),
              onPressed: () async {
                // Delete video file if exists
                if (_session.videoPath != null &&
                    File(_session.videoPath!).existsSync()) {
                  await File(_session.videoPath!).delete();
                }

                // Clear GPS data and video path in the session
                final updatedSession = _session.copy(
                  gpsData: [],
                  videoPath: null,
                  duration: Duration.zero,
                  gpsPoints: 0,
                );
                await DatabaseHelper.instance.updateSession(updatedSession);

                if (!context.mounted) return;
                setState(() {
                  _session = updatedSession;
                  _videoController?.dispose();
                  _videoController = null;
                });
                _calculateSessionData(); // Recalculate stats
                Navigator.of(context).pop(); // Close the dialog
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        SessionCompletionPage(session: updatedSession),
                  ),
                );
                if (!context.mounted) return;
                _refreshSession(); // Refresh session data after returning from completion page
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _exportSessionData() async {
    final sessionData = {
      'id': _session.id,
      'projectId': _session.projectId,
      'name': _session.name,
      'duration': _session.duration.inMilliseconds,
      'gpsPointsCount': _session.gpsPoints,
      'videoPath': _session.videoPath,
      'gpsData': _session.gpsData.map((gpsPoint) => gpsPoint.toMap()).toList(),
    };

    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.10:5160/api/Sessions'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(sessionData),
      );

      if (!mounted) return;
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session exportée avec succès !')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Échec de l'exportation de la session: ${response.statusCode}",
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors de l'exportation de la session: $e"),
        ),
      );
    }
  }
}
