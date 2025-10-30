import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:roadmindphone/database_helper.dart';
import 'package:roadmindphone/project_index_page.dart';

import 'package:roadmindphone/session_gps_point.dart';
import 'package:permission_handler/permission_handler.dart';

class SessionCompletionPage extends StatefulWidget {
  final Session session;

  const SessionCompletionPage({super.key, required this.session});

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

  @override
  void initState() {
    super.initState();
    _determinePosition();
    _initializeCamera();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
    });
  }

  Future<void> _initializeCamera() async {
    // Request microphone permission
    var status = await Permission.microphone.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      // Handle the case where permission is denied
      // You might want to show a dialog or a message to the user
      print("Microphone permission denied. Cannot record audio.");
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
          _gpsData.add(SessionGpsPoint(
            sessionId: widget.session.id!,
            latitude: position.latitude,
            longitude: position.longitude,
            speed: position.speed,
            heading: position.heading,
            timestamp: position.timestamp,
            videoTimestampMs: _duration.inMilliseconds,
          ));
        });
      },
    );
  }

  void _stopRecording() async {
    _timer?.cancel();
    _positionStream?.cancel();

    final XFile? videoFile = await _cameraController?.stopVideoRecording();

    final updatedSession = widget.session.copy(
      duration: _duration,
      gpsPoints: _gpsData.length,
      gpsData: _gpsData,
      videoPath: videoFile?.path,
    );

    await DatabaseHelper.instance.updateSession(updatedSession);

    setState(() {
      _isRecording = false;
    });

    Navigator.of(context).pop();
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
      body: OrientationBuilder(
        builder: (context, orientation) {
          final isLandscape = orientation == Orientation.landscape;
          return isLandscape ? _buildLandscapeLayout() : _buildPortraitLayout();
        },
      ),
    );
  }

  Widget _buildPortraitLayout() {
    return SafeArea(
      child: Column(
        children: <Widget>[
          Expanded(
            flex: 1,
            child: _buildMap(),
          ),
          Expanded(
            flex: 2,
            child: _buildCameraPreview(),
          ),
        ],
      ),
    );
  }

  Widget _buildLandscapeLayout() {
    return Row(
      children: <Widget>[
        Expanded(
          flex: 1,
          child: _buildMap(),
        ),
        Expanded(
          flex: 1,
          child: _buildCameraPreview(),
        ),
      ],
    );
  }

  Widget _buildMap() {
    return _currentLocation == null
        ? const Center(child: CircularProgressIndicator())
        : FlutterMap(
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
                      points: _gpsData
                          .map((p) => p.toLatLng())
                          .toList(),
                      strokeWidth: 4.0,
                      color: Colors.blue,
                    ),
                  ],
                )
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
                child: const Center(
                  child: Text('No Camera Available'),
                ),
              ),
        Positioned(
          bottom: 16.0,
          left: 16.0,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(120, 50),
            ),
                                onPressed: () async {
                                  if (_isRecording) {
                                    _stopRecording();
                                  } else {
                                    await _startRecording();
                                  }            },
            child: Text(_isRecording ? 'Stop' : 'Go!'),
          ),
        ),
      ],
    );
  }
}