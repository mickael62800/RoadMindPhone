import 'package:flutter/foundation.dart';

import '../database_helper.dart';
import '../session.dart';

/// Store responsible for managing the sessions of a project.
///
/// It keeps an in-memory cache of sessions per project and exposes helpers
/// to query loading/error states and mutate the data while notifying listeners.
class SessionStore extends ChangeNotifier {
  final DatabaseHelper _databaseHelper;

  final Map<int, List<Session>> _sessionsByProject = {};
  final Set<int> _loadingProjects = {};
  final Map<int, String?> _errorsByProject = {};

  SessionStore({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  /// Returns an unmodifiable list of sessions for the given [projectId].
  List<Session> sessionsForProject(int projectId) {
    final sessions = _sessionsByProject[projectId];
    return List.unmodifiable(sessions ?? const []);
  }

  /// Whether there is at least one session for the given [projectId].
  bool hasSessions(int projectId) {
    final sessions = _sessionsByProject[projectId];
    return sessions != null && sessions.isNotEmpty;
  }

  /// Returns whether the sessions for the given [projectId] are currently loading.
  bool isLoading(int projectId) => _loadingProjects.contains(projectId);

  /// Returns the error message for the given [projectId], if any.
  String? errorForProject(int projectId) => _errorsByProject[projectId];

  /// Clears the stored error for the given [projectId] and notifies listeners.
  void clearError(int projectId) {
    if (_errorsByProject[projectId] != null) {
      _errorsByProject[projectId] = null;
      notifyListeners();
    }
  }

  /// Loads all sessions for the provided [projectId].
  Future<void> loadSessions(int projectId) async {
    _loadingProjects.add(projectId);
    _errorsByProject[projectId] = null;
    notifyListeners();

    try {
      final sessions = await _databaseHelper.readAllSessionsForProject(
        projectId,
      );
      _sessionsByProject[projectId] = List<Session>.from(sessions);
    } catch (e) {
      _errorsByProject[projectId] =
          'Erreur lors du chargement des sessions: $e';
      rethrow;
    } finally {
      _loadingProjects.remove(projectId);
      notifyListeners();
    }
  }

  /// Creates a session for the given [projectId] and [name].
  Future<Session> createSession({
    required int projectId,
    required String name,
  }) async {
    try {
      final session = Session(
        projectId: projectId,
        name: name,
        duration: Duration.zero,
        gpsPoints: 0,
      );
      final createdSession = await _databaseHelper.createSession(session);
      final sessions = _sessionsByProject.putIfAbsent(
        projectId,
        () => <Session>[],
      );
      sessions.add(createdSession);
      notifyListeners();
      return createdSession;
    } catch (e) {
      _errorsByProject[projectId] =
          'Erreur lors de la création de la session: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Updates the persisted session and synchronises the in-memory cache.
  Future<void> updateSession(Session session) async {
    try {
      await _databaseHelper.updateSession(session);
      final sessions = _sessionsByProject[session.projectId];
      if (sessions != null) {
        final index = sessions.indexWhere((s) => s.id == session.id);
        if (index != -1) {
          sessions[index] = session;
          notifyListeners();
        }
      }
    } catch (e) {
      _errorsByProject[session.projectId] =
          'Erreur lors de la mise à jour de la session: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Deletes the session and removes it from the cache.
  Future<void> deleteSession({
    required int projectId,
    required int sessionId,
  }) async {
    try {
      await _databaseHelper.deleteSession(sessionId);
      final sessions = _sessionsByProject[projectId];
      if (sessions != null) {
        sessions.removeWhere((s) => s.id == sessionId);
        notifyListeners();
      }
    } catch (e) {
      _errorsByProject[projectId] =
          'Erreur lors de la suppression de la session: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Refreshes a single session from the database.
  Future<void> refreshSession({
    required int projectId,
    required int sessionId,
  }) async {
    try {
      final session = await _databaseHelper.readSession(sessionId);
      final sessions = _sessionsByProject.putIfAbsent(
        projectId,
        () => <Session>[],
      );
      final index = sessions.indexWhere((s) => s.id == sessionId);
      if (index == -1) {
        sessions.add(session);
      } else {
        sessions[index] = session;
      }
      notifyListeners();
    } catch (e) {
      _errorsByProject[projectId] =
          'Erreur lors de l\'actualisation de la session: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Clears all cached data. Useful for testing.
  void clearCache() {
    _sessionsByProject.clear();
    _loadingProjects.clear();
    _errorsByProject.clear();
    notifyListeners();
  }
}
