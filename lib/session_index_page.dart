import 'package:roadmindphone/src/ui/widgets/dialogs/rename_dialog.dart';
import 'package:roadmindphone/src/ui/widgets/dialogs/confirm_dialog.dart';
import 'package:roadmindphone/services/session_service/calculate_session_stats.dart';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:roadmindphone/services/location_service.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:roadmindphone/services/session_service/redo_session.dart';
import 'package:roadmindphone/services/session_service/rename_session.dart';
import 'package:roadmindphone/services/session_service/delete_session_with_file.dart';
import 'package:roadmindphone/services/session_service/export_session_data.dart';
import 'package:video_player/video_player.dart';
import 'package:roadmindphone/database_helper.dart';
import 'package:roadmindphone/session.dart';
import 'package:roadmindphone/session_completion_page.dart';
import 'package:roadmindphone/features/session/domain/entities/session_entity.dart';

import 'package:roadmindphone/src/ui/widgets/session/session_detail_layout.dart';
import 'package:roadmindphone/src/ui/widgets/session/session_index_app_bar.dart';
import 'package:roadmindphone/src/ui/widgets/session/session_index_loader.dart';

/// Extension to convert legacy Session to SessionEntity
extension SessionToEntity on Session {
  SessionEntity toEntity() {
    return SessionEntity(
      id: id,
      projectId: projectId,
      name: name,
      duration: duration,
      gpsPoints: gpsPoints,
      videoPath: videoPath,
      gpsData: gpsData,
      startTime: startTime,
      endTime: endTime,
      notes: notes,
      createdAt: DateTime.now(), // Legacy sessions don't have createdAt
      updatedAt: null,
    );
  }
}

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
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _session = widget.session; // Initialize _session with the passed session
    _initialize();
  }

  Future<void> _initialize() async {
    // Charger les données de la session
    await _refreshSession();

    // Debug: vérifier les données GPS
    debugPrint(
      'DEBUG SessionIndexPage: GPS data count = ${_session.gpsData.length}',
    );
    if (_session.gpsData.isNotEmpty) {
      debugPrint(
        'DEBUG SessionIndexPage: First GPS point = ${_session.gpsData.first.latitude}, ${_session.gpsData.first.longitude}',
      );
    }

    // Marquer l'initialisation comme terminée AVANT l'initialisation de la vidéo
    if (mounted) {
      setState(() {
        _isInitializing = false;
      });
    }

    // Initialiser la vidéo APRÈS l'affichage de la page
    _initializeVideo();
  }

  Future<void> _refreshSession() async {
    try {
      final updatedSession = await DatabaseHelper.instance.readSession(
        _session.id,
      );
      if (mounted) {
        _session = updatedSession;
        _calculateSessionDataWithoutSetState();
      }
    } catch (e) {
      debugPrint('Error refreshing session: $e');
    }
    await initializeLocation(
      sessionId: _session.id,
      existingGpsData: _session.gpsData,
    );
  }

  Future<void> _initializeVideo() async {
    if (_session.videoPath != null && File(_session.videoPath!).existsSync()) {
      try {
        _videoController = VideoPlayerController.file(
          File(_session.videoPath!),
        );
        _initializeVideoPlayerFuture = _videoController!.initialize();
        await _initializeVideoPlayerFuture;
        if (mounted) setState(() {});
      } catch (e) {
        debugPrint('Error initializing video: $e');
      }
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _calculateSessionData() {
    final stats = calculateSessionStats(_session);
    setState(() {
      _totalDistance = stats['totalDistance'] ?? 0.0;
      _averageSpeed = stats['averageSpeed'] ?? 0.0;
    });
  }

  void _calculateSessionDataWithoutSetState() {
    final stats = calculateSessionStats(_session);
    _totalDistance = stats['totalDistance'] ?? 0.0;
    _averageSpeed = stats['averageSpeed'] ?? 0.0;
  }

  void _onMenuSelected(String value) {
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
  }

  @override
  Widget build(BuildContext context) {
    // Afficher un loader modulaire pendant l'initialisation
    if (_isInitializing) {
      return Scaffold(
        appBar: SessionIndexAppBar(
          title: _session.name,
          onMenuSelected: _onMenuSelected,
        ),
        body: const SessionIndexLoader(message: 'Chargement de la session...'),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (!didPop) {
          Navigator.of(context).pop(_hasChanged);
        }
      },
      child: Scaffold(
        appBar: SessionIndexAppBar(
          title: _session.name,
          onMenuSelected: _onMenuSelected,
        ),
        body: OrientationBuilder(
          builder: (context, orientation) {
            final isLandscape = orientation == Orientation.landscape;
            return SessionDetailLayout(
              session: _session,
              averageSpeed: _averageSpeed,
              totalDistance: _totalDistance,
              videoController: _videoController,
              initializeVideoPlayerFuture: _initializeVideoPlayerFuture,
              isLandscape: isLandscape,
              flutterMapBuilder: widget.flutterMapBuilder,
            );
          },
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmDialog(
        title: 'Supprimer la session',
        content: 'Êtes-vous sûr de vouloir supprimer cette session ?',
        confirmText: 'SUPPRIMER',
        onConfirm: () {},
      ),
    );
    if (confirmed == true) {
      if (!mounted) return;
      final navigator = Navigator.of(context);
      final result = await deleteSessionWithFile(session: _session);
      if (result && mounted) {
        navigator.pop(true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la suppression.')),
        );
      }
    }
  }

  void _showRenameDialog() async {
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => RenameDialog(
        title: 'Renommer la session',
        hintText: 'Nouveau nom de la session',
        initialValue: _session.name,
      ),
    );
    if (newName != null && newName.isNotEmpty) {
      if (!mounted) return;
      await renameSession(
        context: context,
        session: _session,
        newName: newName,
        onSuccess: (updatedSession) {
          setState(() {
            _session = updatedSession;
            _hasChanged = true;
          });
        },
      );
    }
  }

  void _showRedoConfirmationDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmDialog(
        title: 'Refaire la session',
        content:
            'Êtes-vous sûr de vouloir refaire cette session ? La vidéo et les données GPS seront supprimées.',
        confirmText: 'CONFIRMER',
        onConfirm: () {},
      ),
    );
    if (confirmed == true) {
      if (!mounted) return;
      final navigator = Navigator.of(context);
      await redoSession(
        session: _session,
        onAfterRedo: (updatedSession) async {
          if (!mounted) return;
          setState(() {
            _session = updatedSession;
            _videoController?.dispose();
            _videoController = null;
            _hasChanged = true;
          });
          _calculateSessionData();
          // Naviguer vers la page de complétion pour refaire la session
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
        },
      );
    }
  }

  Future<void> _exportSessionData() async {
    await exportSessionData(
      context: context,
      client: http.Client(),
      baseUrl: 'http://192.168.1.10:5160',
      session: _session,
    );
  }
}
