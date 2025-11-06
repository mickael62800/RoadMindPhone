import 'package:roadmindphone/services/session_service/finalize_session.dart';
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
import 'package:roadmindphone/services/camera_service.dart';
import 'package:roadmindphone/services/location_service.dart';
import 'package:roadmindphone/src/ui/widgets/session/session_completion_app_bar.dart';
import 'package:roadmindphone/src/ui/widgets/session/session_completion_loader.dart';
import 'package:roadmindphone/src/ui/widgets/session/session_completion_layout.dart';
import 'package:roadmindphone/features/session/presentation/bloc/session_bloc.dart';
import 'package:roadmindphone/features/session/presentation/bloc/session_event.dart';
import 'package:roadmindphone/session_index_page.dart'; // Import for SessionToEntity extension

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
  late Session _currentSession;
  LatLng? _currentLocation;
  CameraController? _cameraController;
  // List<CameraDescription>? _cameras; // plus utilisé
  bool _isRecording = false;
  Timer? _timer;
  StreamSubscription<Position>? _positionStream;
  List<SessionGpsPoint> _gpsData = [];
  Duration _duration = Duration.zero;
  final MapController _mapController = MapController();
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    debugPrint(
      'DEBUG SessionCompletionPage: initState - session.gpsData.length = ${widget.session.gpsData.length}',
    );
    // Initialiser la session courante
    _currentSession = widget.session;
    _initialize();
  }

  Future<void> _initialize() async {
    // Initialisation caméra
    final cameraResult = await initializeCamera(
      existingController: widget.cameraController,
      existingCameras: widget.cameras,
      enableAudio: false,
      context: context,
    );
    if (cameraResult.controller != null) {
      _cameraController = cameraResult.controller;
      setState(() {});
    }

    // Initialisation GPS
    final locationResult = await initializeLocation(
      sessionId: widget.session.id,
      existingGpsData: widget.session.gpsData,
    );
    if (locationResult.currentLocation != null) {
      _currentLocation = locationResult.currentLocation;
      _gpsData = locationResult.gpsData;
    }

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

  Future<void> _startRecording() async {
    await _cameraController?.startVideoRecording();
    setState(() {
      _isRecording = true;
      _duration = Duration.zero;
      // Réinitialiser les données GPS (supprimer le point temporaire)
      _gpsData = [];
      // Si startTime absent, créer une copie de la session avec startTime
      if (_currentSession.startTime == null) {
        _currentSession = _currentSession.copy(
          startTime: DateTime.now().toUtc(),
        );
      }
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
                  sessionId: widget.session.id,
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

    // Utiliser le service pour finaliser et sauvegarder la session
    final updatedSession = await finalizeSession(
      session: _currentSession,
      duration: _duration,
      gpsData: _gpsData,
      videoPath: videoFile?.path,
      endTime: DateTime.now().toUtc(),
    );

    // Mettre à jour via le BLoC pour la cohérence UI
    if (mounted) {
      try {
        final bloc = context.read<SessionBloc>();
        final entity = updatedSession.toEntity();
        bloc.add(UpdateSessionEvent(entity));
      } catch (e) {
        debugPrint('DEBUG: Error updating via BLoC: $e');
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
    if (_isInitializing) {
      return Scaffold(
        appBar: SessionCompletionAppBar(
          title: widget.session.name,
          info: '',
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: const SessionCompletionLoader(),
      );
    }

    return Scaffold(
      appBar: SessionCompletionAppBar(
        title: widget.session.name,
        info:
            'Durée: ${_formatDuration(_duration)} | GPS Points: ${_gpsData.length}',
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            final isLandscape = orientation == Orientation.landscape;
            return SessionCompletionLayout(
              isLandscape: isLandscape,
              currentLocation: _currentLocation,
              gpsData: _gpsData,
              cameraController: _cameraController,
              isRecording: _isRecording,
              onAction: () async {
                if (_isRecording) {
                  _stopRecording();
                } else {
                  await _startRecording();
                }
              },
              flutterMapBuilder: widget.flutterMapBuilder,
              mapController: _mapController,
            );
          },
        ),
      ),
    );
  }
}
