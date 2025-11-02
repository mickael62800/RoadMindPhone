import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:roadmindphone/database_helper.dart';
import 'package:roadmindphone/session.dart';
import 'package:roadmindphone/session_completion_page.dart';
import 'package:roadmindphone/stores/session_store.dart';

import 'package:roadmindphone/src/ui/molecules/molecules.dart';
import 'package:roadmindphone/src/ui/widgets/session_detail/session_detail_widgets.dart';

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
  Future<void>? _initializeVideoPlayerFuture;
  bool _hasChanged = false;

  @override
  void initState() {
    super.initState();
    _session = widget.session; // Initialize _session with the passed session
    _refreshSession();
  }

  Future<void> _refreshSession() async {
    // Refresh via SessionStore (which will read from database)
    if (mounted) {
      try {
        await context.read<SessionStore>().refreshSession(
          projectId: _session.projectId,
          sessionId: _session.id!,
        );
        // Get the updated session from the store
        final updatedSession = await DatabaseHelper.instance.readSession(
          _session.id!,
        );
        setState(() {
          _session = updatedSession;
          _calculateSessionData();
        });
      } catch (e) {
        // Fallback: if SessionStore is not available, read directly from database
        final updatedSession = await DatabaseHelper.instance.readSession(
          _session.id!,
        );
        setState(() {
          _session = updatedSession;
          _calculateSessionData();
        });
      }
    }

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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (!didPop) {
          Navigator.of(context).pop(_hasChanged);
        }
      },
      child: Scaffold(
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
            final statsWidget = SessionStatsWidget(
              session: _session,
              averageSpeed: _averageSpeed,
              totalDistance: _totalDistance,
            );

            final mapWidget = SessionMapWidget(
              session: _session,
              mapBuilder: widget.flutterMapBuilder,
              isLandscape: isLandscape,
            );

            final videoWidget = SessionVideoPlayerWidget(
              videoController: _videoController,
              initializeVideoPlayerFuture: _initializeVideoPlayerFuture,
              isLandscape: isLandscape,
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
                      child: statsWidget,
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Row(children: [mapWidget, videoWidget]),
                  ),
                ],
              );
            } else {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16.0),
                    statsWidget,
                    const SizedBox(height: 16.0),
                    mapWidget,
                    const SizedBox(height: 16.0),
                    videoWidget,
                    const SizedBox(height: 16.0),
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog() async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Supprimer la session',
      content: 'Êtes-vous sûr de vouloir supprimer cette session ?',
      confirmText: 'SUPPRIMER',
    );

    if (confirmed == true) {
      if (!mounted) return;
      final navigator = Navigator.of(context);

      // Delete via SessionStore (with fallback for tests without Provider)
      try {
        final sessionStore = context.read<SessionStore>();
        await sessionStore.deleteSession(
          projectId: _session.projectId,
          sessionId: _session.id!,
        );
      } catch (e) {
        // Fallback for tests without Provider
        await DatabaseHelper.instance.deleteSession(_session.id!);
      }
      if (!mounted) return;
      navigator.pop(true); // Go back and indicate change
    }
  }

  void _showRenameDialog() async {
    final newName = await showRenameDialog(
      context: context,
      title: 'Renommer la session',
      hintText: 'Nouveau nom de la session',
      initialValue: _session.name,
    );

    if (newName != null && newName.isNotEmpty) {
      if (!mounted) return;

      final updatedSession = _session.copy(name: newName);
      // Update via SessionStore (with fallback for tests without Provider)
      try {
        final sessionStore = context.read<SessionStore>();
        await sessionStore.updateSession(updatedSession);
      } catch (e) {
        // Fallback for tests without Provider
        await DatabaseHelper.instance.updateSession(updatedSession);
      }
      if (!mounted) return;
      setState(() {
        _session = updatedSession;
        _hasChanged = true;
      });
    }
  }

  void _showRedoConfirmationDialog() async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Refaire la session',
      content:
          'Êtes-vous sûr de vouloir refaire cette session ? La vidéo et les données GPS seront supprimées.',
      confirmText: 'CONFIRMER',
    );

    if (confirmed == true) {
      if (!mounted) return;
      final navigator = Navigator.of(context);

      // Capture SessionStore before any async operations (or use fallback)
      SessionStore? sessionStore;
      try {
        sessionStore = context.read<SessionStore>();
      } catch (e) {
        // No Provider available (tests), will use DatabaseHelper fallback
        sessionStore = null;
      }

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

      // Update via SessionStore or DatabaseHelper fallback
      if (sessionStore != null) {
        await sessionStore.updateSession(updatedSession);
      } else {
        await DatabaseHelper.instance.updateSession(updatedSession);
      }

      if (!mounted) return;
      setState(() {
        _session = updatedSession;
        _videoController?.dispose();
        _videoController = null;
        _hasChanged = true;
      });
      _calculateSessionData(); // Recalculate stats

      // Navigate to SessionCompletionPage to redo the session
      final Session? newSessionData = await navigator.push<Session>(
        MaterialPageRoute(
          builder: (context) => SessionCompletionPage(
            session: updatedSession,
            flutterMapBuilder: widget.flutterMapBuilder,
          ),
        ),
      );
      if (newSessionData != null && mounted) {
        setState(() {
          _session = newSessionData;
          _calculateSessionData();
          if (_session.videoPath != null &&
              File(_session.videoPath!).existsSync()) {
            _videoController = VideoPlayerController.file(
              File(_session.videoPath!),
            );
            _initializeVideoPlayerFuture = _videoController!.initialize();
          } else {
            _videoController?.dispose();
            _videoController = null;
          }
        });
      }
    }
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
