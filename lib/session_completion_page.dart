import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:roadmindphone/database_helper.dart';
import 'package:roadmindphone/session.dart'; // Import Session class
import 'package:roadmindphone/session_gps_point.dart';
import 'package:roadmindphone/features/session/presentation/bloc/session_bloc.dart';
import 'package:roadmindphone/features/session/presentation/bloc/session_event.dart';
import 'package:roadmindphone/session_index_page.dart'; // Import for SessionToEntity extension
import 'package:permission_handler/permission_handler.dart';

typedef FlutterMapBuilder =
    Widget Function({
      Key? key,
      required MapOptions options,
      List<Widget>? children,
      MapController? mapController,
    });

class SessionCompletionPage extends StatefulWidget {
  final Session session;
  final FlutterMapBuilder flutterMapBuilder;
  final DatabaseHelper? databaseHelper;
  final CameraController? cameraController;
  final List<CameraDescription>? cameras;

  const SessionCompletionPage({
    super.key,
    required this.session,
    this.flutterMapBuilder = _defaultFlutterMapBuilder,
    this.databaseHelper,
    this.cameraController,
    this.cameras,
  });

  static Widget _defaultFlutterMapBuilder({
    Key? key,
    required MapOptions options,
    List<Widget>? children,
    MapController? mapController,
  }) {
    return FlutterMap(
      key: key,
      options: options,
      mapController: mapController,
      children: children ?? [],
    );
  }

  @override
  State<SessionCompletionPage> createState() => _SessionCompletionPageState();
}

class _SessionCompletionPageState extends State<SessionCompletionPage> {
  LatLng? _currentLocation;
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isRecording = false;
  Timer? _timer;
  StreamSubscription<Position>? _positionStream;
  List<SessionGpsPoint> _gpsData = [];
  Duration _duration = Duration.zero;
  late DatabaseHelper _databaseHelper;
  final MapController _mapController = MapController();
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    debugPrint(
      'DEBUG SessionCompletionPage: initState - session.gpsData.length = ${widget.session.gpsData.length}',
    );
    _databaseHelper = widget.databaseHelper ?? DatabaseHelper.instance;
    _initialize();
  }

  Future<void> _initialize() async {
    await Future.wait([_initializeCamera(), _determinePosition()]);

    setState(() {
      _isInitializing = false;
    });

    // Déplacer la carte vers la position actuelle après initialisation
    if (_currentLocation != null) {
      debugPrint('DEBUG: Moving map to $_currentLocation after initialization');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          _mapController.move(_currentLocation!, 18.0);
          debugPrint('DEBUG: Map moved to current location');

          // Forcer un léger mouvement pour déclencher le chargement des tuiles
          Future.delayed(const Duration(milliseconds: 100), () {
            try {
              _mapController.move(
                LatLng(
                  _currentLocation!.latitude + 0.00001,
                  _currentLocation!.longitude,
                ),
                18.0,
              );
              Future.delayed(const Duration(milliseconds: 50), () {
                try {
                  _mapController.move(_currentLocation!, 18.0);
                } catch (e) {
                  debugPrint('DEBUG: Error moving map (final): $e');
                }
              });
            } catch (e) {
              debugPrint('DEBUG: Error moving map (micro): $e');
            }
          });
        } catch (e) {
          debugPrint('DEBUG: Error moving map (initial): $e');
        }
      });
    }
  }

  Future<void> _determinePosition() async {
    debugPrint('DEBUG: _determinePosition called');
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('DEBUG: Location services are disabled');
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      debugPrint('DEBUG: Location permission denied, requesting');
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('DEBUG: Location permission denied after request');
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('DEBUG: Location permission denied forever');
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }

    debugPrint('DEBUG: Getting current position...');
    Position position = await Geolocator.getCurrentPosition();
    debugPrint(
      'DEBUG: Position obtained: ${position.latitude}, ${position.longitude}',
    );

    _currentLocation = LatLng(position.latitude, position.longitude);
    debugPrint('DEBUG: _currentLocation set to $_currentLocation');
    debugPrint(
      'DEBUG: widget.session.gpsData.isEmpty = ${widget.session.gpsData.isEmpty}',
    );

    // Si la session n'a pas de points GPS (nouveau ou "Refaire"),
    // ajouter un point GPS temporaire à la position actuelle pour centrer la carte
    if (widget.session.gpsData.isEmpty) {
      debugPrint('DEBUG: Creating temporary GPS point');
      _gpsData = [
        SessionGpsPoint(
          sessionId: widget.session.id!,
          latitude: position.latitude,
          longitude: position.longitude,
          speed: position.speed,
          heading: position.heading,
          timestamp: position.timestamp,
          videoTimestampMs: 0,
        ),
      ];
      debugPrint(
        'DEBUG: Temporary GPS point created, _gpsData.length = ${_gpsData.length}',
      );
    } else {
      debugPrint(
        'DEBUG: Using existing GPS data, count = ${widget.session.gpsData.length}',
      );
      _gpsData = List.from(widget.session.gpsData);
    }

    debugPrint('DEBUG: GPS initialization completed');
  }

  Future<void> _initializeCamera() async {
    if (widget.cameraController != null) {
      _cameraController = widget.cameraController;
      _cameras = widget.cameras;
      if (_cameraController!.value.isInitialized) {
        setState(() {});
      }
      return;
    }

    // Request microphone permission
    var status = await Permission.microphone.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      // Handle the case where permission is denied
      // You might want to show a dialog or a message to the user
      debugPrint("Microphone permission denied. Cannot record audio.");
      return;
    }

    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      _cameraController = CameraController(
        _cameras![0],
        ResolutionPreset.medium,
        enableAudio: false,
      );

      _cameraController!.initialize().then((_) {
        if (!mounted) {
          return;
        }
        setState(() {});
      });
    }
  }

  Future<void> _startRecording() async {
    await _cameraController?.startVideoRecording();
    setState(() {
      _isRecording = true;
      _duration = Duration.zero;
      // Réinitialiser les données GPS (supprimer le point temporaire)
      _gpsData = [];
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _duration = Duration(seconds: _duration.inSeconds + 1);
      });
    });

    final LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 1,
    );
    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            setState(() {
              _currentLocation = LatLng(position.latitude, position.longitude);
              _gpsData.add(
                SessionGpsPoint(
                  sessionId: widget.session.id!,
                  latitude: position.latitude,
                  longitude: position.longitude,
                  speed: position.speed,
                  heading: position.heading,
                  timestamp: position.timestamp,
                  videoTimestampMs: _duration.inMilliseconds,
                ),
              );
            });
          },
        );
  }

  void _stopRecording() async {
    debugPrint('DEBUG: _stopRecording called');
    _timer?.cancel();
    _positionStream?.cancel();

    final XFile? videoFile = await _cameraController?.stopVideoRecording();
    debugPrint('DEBUG: Video file path: ${videoFile?.path}');

    final updatedSession = widget.session.copy(
      duration: _duration,
      gpsPoints: _gpsData.length,
      gpsData: _gpsData,
      videoPath: videoFile?.path,
    );

    debugPrint(
      'DEBUG: Updated session - id: ${updatedSession.id}, duration: ${updatedSession.duration}, gpsPoints: ${updatedSession.gpsPoints}',
    );

    // Update via SessionBloc
    if (mounted) {
      try {
        debugPrint('DEBUG: Updating session via BLoC and DatabaseHelper');
        final bloc = context.read<SessionBloc>();
        // Convert to entity using the extension from session_index_page
        final entity = updatedSession.toEntity();
        bloc.add(UpdateSessionEvent(entity));

        // Also update database directly for immediate consistency
        await _databaseHelper.updateSession(updatedSession);
        debugPrint('DEBUG: Session updated successfully in database');
      } catch (e) {
        debugPrint('DEBUG: Error updating via BLoC, using fallback: $e');
        // Fallback: update the database directly
        await _databaseHelper.updateSession(updatedSession);
        debugPrint('DEBUG: Session updated via fallback');
      }
    }

    if (!mounted) return;
    setState(() {
      _isRecording = false;
    });

    debugPrint('DEBUG: Popping navigation with updated session');
    Navigator.of(context).pop(updatedSession);
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _timer?.cancel();
    _positionStream?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    // Afficher un loader pendant l'initialisation
    if (_isInitializing) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.session.name),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initialisation en cours...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.session.name),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(30.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Durée: ${_formatDuration(_duration)} | GPS Points: ${_gpsData.length}',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            final isLandscape = orientation == Orientation.landscape;
            return isLandscape
                ? _buildLandscapeLayout()
                : _buildPortraitLayout();
          },
        ),
      ),
    );
  }

  Widget _buildPortraitLayout() {
    return Column(
      key: const Key('portrait_layout'),
      children: <Widget>[
        Expanded(flex: 1, child: _buildMap()),
        Expanded(flex: 2, child: _buildCameraPreview()),
      ],
    );
  }

  Widget _buildLandscapeLayout() {
    return Row(
      key: const Key('landscape_layout'),
      children: <Widget>[
        Expanded(flex: 1, child: _buildMap()),
        Expanded(flex: 1, child: _buildCameraPreview()),
      ],
    );
  }

  Widget _buildMap() {
    debugPrint('DEBUG _buildMap: _currentLocation = $_currentLocation');
    debugPrint('DEBUG _buildMap: _gpsData.length = ${_gpsData.length}');

    return _currentLocation == null
        ? const Center(child: CircularProgressIndicator())
        : widget.flutterMapBuilder(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation ?? const LatLng(50.42, 2.83),
              initialZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
              ),
              if (_currentLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 80.0,
                      height: 80.0,
                      point: _currentLocation!,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 40.0,
                      ),
                    ),
                  ],
                ),
              if (_gpsData.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _gpsData.map((p) => p.toLatLng()).toList(),
                      strokeWidth: 4.0,
                      color: Colors.blue,
                    ),
                  ],
                ),
            ],
          );
  }

  Widget _buildCameraPreview() {
    return Stack(
      children: [
        _cameraController != null && _cameraController!.value.isInitialized
            ? CameraPreview(_cameraController!)
            : Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Center(child: Text('No Camera Available')),
              ),
        Positioned(
          bottom: 16.0,
          left: 16.0,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(120, 50)),
            onPressed: () async {
              if (_isRecording) {
                _stopRecording();
              } else {
                await _startRecording();
              }
            },
            child: Text(_isRecording ? 'Stop' : 'Go!'),
          ),
        ),
      ],
    );
  }
}
