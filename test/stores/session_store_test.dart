import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:roadmindphone/session.dart';
import 'package:roadmindphone/stores/session_store.dart';

import '../mocks.mocks.dart';

void main() {
  group('SessionStore', () {
    late MockDatabaseHelper mockDbHelper;
    late SessionStore sessionStore;

    setUp(() {
      mockDbHelper = MockDatabaseHelper();
      sessionStore = SessionStore(databaseHelper: mockDbHelper);
    });

    test('initial state is empty', () {
      expect(sessionStore.sessionsForProject(1), isEmpty);
      expect(sessionStore.isLoading(1), false);
      expect(sessionStore.errorForProject(1), isNull);
      expect(sessionStore.hasSessions(1), false);
    });

    group('loadSessions', () {
      test('loads sessions successfully', () async {
        final sessions = [
          Session(
            id: 1,
            projectId: 1,
            name: 'Session 1',
            duration: const Duration(minutes: 30),
            gpsPoints: 100,
          ),
          Session(
            id: 2,
            projectId: 1,
            name: 'Session 2',
            duration: const Duration(minutes: 45),
            gpsPoints: 150,
          ),
        ];
        when(
          mockDbHelper.readAllSessionsForProject(1),
        ).thenAnswer((_) async => sessions);

        await sessionStore.loadSessions(1);

        expect(sessionStore.sessionsForProject(1), equals(sessions));
        expect(sessionStore.isLoading(1), false);
        expect(sessionStore.errorForProject(1), isNull);
        expect(sessionStore.hasSessions(1), true);
      });

      test('sets loading state during load', () async {
        when(mockDbHelper.readAllSessionsForProject(1)).thenAnswer(
          (_) async =>
              Future.delayed(const Duration(milliseconds: 100), () => []),
        );

        final loadFuture = sessionStore.loadSessions(1);

        // Check loading state is set
        expect(sessionStore.isLoading(1), true);

        await loadFuture;

        expect(sessionStore.isLoading(1), false);
      });

      test('clears previous error on load', () async {
        // First, create an error
        when(
          mockDbHelper.readAllSessionsForProject(1),
        ).thenThrow(Exception('First error'));

        try {
          await sessionStore.loadSessions(1);
        } catch (_) {}

        expect(sessionStore.errorForProject(1), isNotNull);

        // Now load successfully
        when(
          mockDbHelper.readAllSessionsForProject(1),
        ).thenAnswer((_) async => []);

        await sessionStore.loadSessions(1);

        expect(sessionStore.errorForProject(1), isNull);
      });

      test('handles errors and sets error message', () async {
        when(
          mockDbHelper.readAllSessionsForProject(1),
        ).thenThrow(Exception('Database error'));

        expect(() => sessionStore.loadSessions(1), throwsA(isA<Exception>()));

        expect(
          sessionStore.errorForProject(1),
          contains('Erreur lors du chargement'),
        );
        expect(sessionStore.isLoading(1), false);
      });

      test('loads sessions for multiple projects independently', () async {
        final sessionsProject1 = [
          Session(
            id: 1,
            projectId: 1,
            name: 'Session 1-1',
            duration: Duration.zero,
            gpsPoints: 0,
          ),
        ];
        final sessionsProject2 = [
          Session(
            id: 2,
            projectId: 2,
            name: 'Session 2-1',
            duration: Duration.zero,
            gpsPoints: 0,
          ),
        ];

        when(
          mockDbHelper.readAllSessionsForProject(1),
        ).thenAnswer((_) async => sessionsProject1);
        when(
          mockDbHelper.readAllSessionsForProject(2),
        ).thenAnswer((_) async => sessionsProject2);

        await sessionStore.loadSessions(1);
        await sessionStore.loadSessions(2);

        expect(sessionStore.sessionsForProject(1), equals(sessionsProject1));
        expect(sessionStore.sessionsForProject(2), equals(sessionsProject2));
        expect(sessionStore.hasSessions(1), true);
        expect(sessionStore.hasSessions(2), true);
      });
    });

    group('createSession', () {
      test('creates and adds session successfully', () async {
        final newSession = Session(
          id: 1,
          projectId: 1,
          name: 'New Session',
          duration: Duration.zero,
          gpsPoints: 0,
        );
        when(
          mockDbHelper.createSession(any),
        ).thenAnswer((_) async => newSession);

        final result = await sessionStore.createSession(
          projectId: 1,
          name: 'New Session',
        );

        expect(result, equals(newSession));
        expect(sessionStore.sessionsForProject(1), contains(newSession));
        expect(sessionStore.hasSessions(1), true);
        verify(mockDbHelper.createSession(any)).called(1);
      });

      test('adds session to existing list', () async {
        // Load initial sessions
        final initialSessions = [
          Session(
            id: 1,
            projectId: 1,
            name: 'Session 1',
            duration: Duration.zero,
            gpsPoints: 0,
          ),
        ];
        when(
          mockDbHelper.readAllSessionsForProject(1),
        ).thenAnswer((_) async => initialSessions);
        await sessionStore.loadSessions(1);

        // Create new session
        final newSession = Session(
          id: 2,
          projectId: 1,
          name: 'Session 2',
          duration: Duration.zero,
          gpsPoints: 0,
        );
        when(
          mockDbHelper.createSession(any),
        ).thenAnswer((_) async => newSession);

        await sessionStore.createSession(projectId: 1, name: 'Session 2');

        expect(sessionStore.sessionsForProject(1).length, 2);
        expect(sessionStore.sessionsForProject(1), contains(newSession));
      });

      test('handles creation errors and sets error message', () async {
        when(
          mockDbHelper.createSession(any),
        ).thenThrow(Exception('Create error'));

        expect(
          () => sessionStore.createSession(projectId: 1, name: 'Test'),
          throwsA(isA<Exception>()),
        );

        expect(
          sessionStore.errorForProject(1),
          contains('Erreur lors de la création'),
        );
      });

      test('creates session for new project', () async {
        final newSession = Session(
          id: 1,
          projectId: 5,
          name: 'First Session',
          duration: Duration.zero,
          gpsPoints: 0,
        );
        when(
          mockDbHelper.createSession(any),
        ).thenAnswer((_) async => newSession);

        await sessionStore.createSession(projectId: 5, name: 'First Session');

        expect(sessionStore.hasSessions(5), true);
        expect(sessionStore.sessionsForProject(5).length, 1);
      });
    });

    group('updateSession', () {
      test('updates existing session successfully', () async {
        // Setup initial sessions
        final initialSessions = [
          Session(
            id: 1,
            projectId: 1,
            name: 'Initial Name',
            duration: const Duration(minutes: 10),
            gpsPoints: 50,
          ),
        ];
        when(
          mockDbHelper.readAllSessionsForProject(1),
        ).thenAnswer((_) async => initialSessions);
        await sessionStore.loadSessions(1);

        // Update the session
        final updatedSession = Session(
          id: 1,
          projectId: 1,
          name: 'Updated Name',
          duration: const Duration(minutes: 20),
          gpsPoints: 100,
        );
        when(mockDbHelper.updateSession(any)).thenAnswer((_) async => 1);

        await sessionStore.updateSession(updatedSession);

        expect(sessionStore.sessionsForProject(1).first.name, 'Updated Name');
        expect(
          sessionStore.sessionsForProject(1).first.duration,
          const Duration(minutes: 20),
        );
        expect(sessionStore.sessionsForProject(1).first.gpsPoints, 100);
        verify(mockDbHelper.updateSession(updatedSession)).called(1);
      });

      test('handles update when session not in cache', () async {
        final session = Session(
          id: 999,
          projectId: 1,
          name: 'Non-existent',
          duration: Duration.zero,
          gpsPoints: 0,
        );
        when(mockDbHelper.updateSession(any)).thenAnswer((_) async => 1);

        await sessionStore.updateSession(session);

        // Should not crash, cache remains empty
        expect(sessionStore.sessionsForProject(1), isEmpty);
      });

      test('handles update when project not loaded', () async {
        final session = Session(
          id: 1,
          projectId: 999,
          name: 'Test',
          duration: Duration.zero,
          gpsPoints: 0,
        );
        when(mockDbHelper.updateSession(any)).thenAnswer((_) async => 1);

        await sessionStore.updateSession(session);

        // Should not crash
        expect(sessionStore.sessionsForProject(999), isEmpty);
      });

      test('handles update errors and sets error message', () async {
        final session = Session(
          id: 1,
          projectId: 1,
          name: 'Test',
          duration: Duration.zero,
          gpsPoints: 0,
        );
        when(
          mockDbHelper.updateSession(any),
        ).thenThrow(Exception('Update error'));

        expect(
          () => sessionStore.updateSession(session),
          throwsA(isA<Exception>()),
        );

        expect(
          sessionStore.errorForProject(1),
          contains('Erreur lors de la mise à jour'),
        );
      });
    });

    group('deleteSession', () {
      test('deletes session successfully', () async {
        // Setup initial sessions
        final sessions = [
          Session(
            id: 1,
            projectId: 1,
            name: 'Session 1',
            duration: Duration.zero,
            gpsPoints: 0,
          ),
          Session(
            id: 2,
            projectId: 1,
            name: 'Session 2',
            duration: Duration.zero,
            gpsPoints: 0,
          ),
        ];
        when(
          mockDbHelper.readAllSessionsForProject(1),
        ).thenAnswer((_) async => sessions);
        await sessionStore.loadSessions(1);

        when(mockDbHelper.deleteSession(1)).thenAnswer((_) async => 1);

        await sessionStore.deleteSession(projectId: 1, sessionId: 1);

        expect(sessionStore.sessionsForProject(1).length, 1);
        expect(sessionStore.sessionsForProject(1).any((s) => s.id == 1), false);
        expect(sessionStore.sessionsForProject(1).any((s) => s.id == 2), true);
        verify(mockDbHelper.deleteSession(1)).called(1);
      });

      test('deletes last session', () async {
        final sessions = [
          Session(
            id: 1,
            projectId: 1,
            name: 'Only Session',
            duration: Duration.zero,
            gpsPoints: 0,
          ),
        ];
        when(
          mockDbHelper.readAllSessionsForProject(1),
        ).thenAnswer((_) async => sessions);
        await sessionStore.loadSessions(1);

        when(mockDbHelper.deleteSession(1)).thenAnswer((_) async => 1);

        await sessionStore.deleteSession(projectId: 1, sessionId: 1);

        expect(sessionStore.sessionsForProject(1), isEmpty);
        expect(sessionStore.hasSessions(1), false);
      });

      test('handles delete when session not in cache', () async {
        when(mockDbHelper.deleteSession(999)).thenAnswer((_) async => 1);

        await sessionStore.deleteSession(projectId: 1, sessionId: 999);

        // Should not crash
        expect(sessionStore.sessionsForProject(1), isEmpty);
      });

      test('handles delete errors and sets error message', () async {
        when(
          mockDbHelper.deleteSession(1),
        ).thenThrow(Exception('Delete error'));

        expect(
          () => sessionStore.deleteSession(projectId: 1, sessionId: 1),
          throwsA(isA<Exception>()),
        );

        expect(
          sessionStore.errorForProject(1),
          contains('Erreur lors de la suppression'),
        );
      });
    });

    group('refreshSession', () {
      test('refreshes existing session successfully', () async {
        // Setup initial sessions
        final initialSessions = [
          Session(
            id: 1,
            projectId: 1,
            name: 'Old Name',
            duration: const Duration(minutes: 10),
            gpsPoints: 50,
          ),
        ];
        when(
          mockDbHelper.readAllSessionsForProject(1),
        ).thenAnswer((_) async => initialSessions);
        await sessionStore.loadSessions(1);

        // Refresh with new data
        final refreshedSession = Session(
          id: 1,
          projectId: 1,
          name: 'New Name',
          duration: const Duration(minutes: 20),
          gpsPoints: 100,
        );
        when(
          mockDbHelper.readSession(1),
        ).thenAnswer((_) async => refreshedSession);

        await sessionStore.refreshSession(projectId: 1, sessionId: 1);

        expect(sessionStore.sessionsForProject(1).first.name, 'New Name');
        expect(
          sessionStore.sessionsForProject(1).first.duration,
          const Duration(minutes: 20),
        );
        expect(sessionStore.sessionsForProject(1).first.gpsPoints, 100);
      });

      test('adds session if not in cache', () async {
        final newSession = Session(
          id: 1,
          projectId: 1,
          name: 'New Session',
          duration: Duration.zero,
          gpsPoints: 0,
        );
        when(mockDbHelper.readSession(1)).thenAnswer((_) async => newSession);

        await sessionStore.refreshSession(projectId: 1, sessionId: 1);

        expect(sessionStore.hasSessions(1), true);
        expect(sessionStore.sessionsForProject(1).length, 1);
        expect(sessionStore.sessionsForProject(1).first, equals(newSession));
      });

      test('refreshes specific session in list', () async {
        final sessions = [
          Session(
            id: 1,
            projectId: 1,
            name: 'Session 1',
            duration: Duration.zero,
            gpsPoints: 0,
          ),
          Session(
            id: 2,
            projectId: 1,
            name: 'Old Session 2',
            duration: Duration.zero,
            gpsPoints: 0,
          ),
          Session(
            id: 3,
            projectId: 1,
            name: 'Session 3',
            duration: Duration.zero,
            gpsPoints: 0,
          ),
        ];
        when(
          mockDbHelper.readAllSessionsForProject(1),
        ).thenAnswer((_) async => sessions);
        await sessionStore.loadSessions(1);

        final refreshedSession = Session(
          id: 2,
          projectId: 1,
          name: 'New Session 2',
          duration: const Duration(minutes: 30),
          gpsPoints: 200,
        );
        when(
          mockDbHelper.readSession(2),
        ).thenAnswer((_) async => refreshedSession);

        await sessionStore.refreshSession(projectId: 1, sessionId: 2);

        expect(sessionStore.sessionsForProject(1).length, 3);
        expect(sessionStore.sessionsForProject(1)[0].name, 'Session 1');
        expect(sessionStore.sessionsForProject(1)[1].name, 'New Session 2');
        expect(sessionStore.sessionsForProject(1)[2].name, 'Session 3');
      });

      test('handles refresh errors and sets error message', () async {
        when(mockDbHelper.readSession(1)).thenThrow(Exception('Refresh error'));

        expect(
          () => sessionStore.refreshSession(projectId: 1, sessionId: 1),
          throwsA(isA<Exception>()),
        );

        expect(
          sessionStore.errorForProject(1),
          contains('Erreur lors de l\'actualisation'),
        );
      });
    });

    group('errorForProject and clearError', () {
      test('clearError removes error message', () async {
        // Create an error
        when(
          mockDbHelper.readAllSessionsForProject(1),
        ).thenThrow(Exception('Test error'));

        try {
          await sessionStore.loadSessions(1);
        } catch (_) {}

        expect(sessionStore.errorForProject(1), isNotNull);

        sessionStore.clearError(1);

        expect(sessionStore.errorForProject(1), isNull);
      });

      test('clearError does nothing if no error exists', () {
        expect(sessionStore.errorForProject(1), isNull);

        sessionStore.clearError(1);

        expect(sessionStore.errorForProject(1), isNull);
      });

      test('errors are project-specific', () async {
        when(
          mockDbHelper.readAllSessionsForProject(1),
        ).thenThrow(Exception('Error 1'));
        when(
          mockDbHelper.readAllSessionsForProject(2),
        ).thenThrow(Exception('Error 2'));

        try {
          await sessionStore.loadSessions(1);
        } catch (_) {}
        try {
          await sessionStore.loadSessions(2);
        } catch (_) {}

        expect(sessionStore.errorForProject(1), isNotNull);
        expect(sessionStore.errorForProject(2), isNotNull);

        sessionStore.clearError(1);

        expect(sessionStore.errorForProject(1), isNull);
        expect(sessionStore.errorForProject(2), isNotNull);
      });
    });

    group('hasSessions', () {
      test('returns false for empty project', () {
        expect(sessionStore.hasSessions(1), false);
      });

      test('returns false for project with empty list', () async {
        when(
          mockDbHelper.readAllSessionsForProject(1),
        ).thenAnswer((_) async => []);
        await sessionStore.loadSessions(1);

        expect(sessionStore.hasSessions(1), false);
      });

      test('returns true for project with sessions', () async {
        final sessions = [
          Session(
            id: 1,
            projectId: 1,
            name: 'Session 1',
            duration: Duration.zero,
            gpsPoints: 0,
          ),
        ];
        when(
          mockDbHelper.readAllSessionsForProject(1),
        ).thenAnswer((_) async => sessions);
        await sessionStore.loadSessions(1);

        expect(sessionStore.hasSessions(1), true);
      });
    });

    group('sessionsForProject', () {
      test('returns unmodifiable list', () {
        final sessions = sessionStore.sessionsForProject(1);

        expect(
          () => (sessions as List).add(
            Session(
              id: 1,
              projectId: 1,
              name: 'Test',
              duration: Duration.zero,
              gpsPoints: 0,
            ),
          ),
          throwsA(isA<UnsupportedError>()),
        );
      });

      test('returns empty list for non-existent project', () {
        expect(sessionStore.sessionsForProject(999), isEmpty);
      });
    });

    group('clearCache', () {
      test('clears all cached data', () async {
        // Load data for multiple projects
        final sessions1 = [
          Session(
            id: 1,
            projectId: 1,
            name: 'Session 1',
            duration: Duration.zero,
            gpsPoints: 0,
          ),
        ];
        final sessions2 = [
          Session(
            id: 2,
            projectId: 2,
            name: 'Session 2',
            duration: Duration.zero,
            gpsPoints: 0,
          ),
        ];

        when(
          mockDbHelper.readAllSessionsForProject(1),
        ).thenAnswer((_) async => sessions1);
        when(
          mockDbHelper.readAllSessionsForProject(2),
        ).thenAnswer((_) async => sessions2);

        await sessionStore.loadSessions(1);
        await sessionStore.loadSessions(2);

        // Create an error
        when(
          mockDbHelper.readAllSessionsForProject(3),
        ).thenThrow(Exception('Error'));
        try {
          await sessionStore.loadSessions(3);
        } catch (_) {}

        expect(sessionStore.hasSessions(1), true);
        expect(sessionStore.hasSessions(2), true);
        expect(sessionStore.errorForProject(3), isNotNull);

        sessionStore.clearCache();

        expect(sessionStore.sessionsForProject(1), isEmpty);
        expect(sessionStore.sessionsForProject(2), isEmpty);
        expect(sessionStore.hasSessions(1), false);
        expect(sessionStore.hasSessions(2), false);
        expect(sessionStore.isLoading(1), false);
        expect(sessionStore.errorForProject(3), isNull);
      });
    });

    group('notifyListeners', () {
      test('notifies listeners on loadSessions', () async {
        var notificationCount = 0;
        sessionStore.addListener(() => notificationCount++);

        when(
          mockDbHelper.readAllSessionsForProject(1),
        ).thenAnswer((_) async => []);

        await sessionStore.loadSessions(1);

        // Should notify at start (loading=true) and end (loading=false)
        expect(notificationCount, greaterThanOrEqualTo(2));
      });

      test('notifies listeners on createSession', () async {
        var notificationCount = 0;
        sessionStore.addListener(() => notificationCount++);

        final newSession = Session(
          id: 1,
          projectId: 1,
          name: 'New Session',
          duration: Duration.zero,
          gpsPoints: 0,
        );
        when(
          mockDbHelper.createSession(any),
        ).thenAnswer((_) async => newSession);

        await sessionStore.createSession(projectId: 1, name: 'New Session');

        expect(notificationCount, greaterThanOrEqualTo(1));
      });

      test('notifies listeners on updateSession', () async {
        // Setup
        final sessions = [
          Session(
            id: 1,
            projectId: 1,
            name: 'Session',
            duration: Duration.zero,
            gpsPoints: 0,
          ),
        ];
        when(
          mockDbHelper.readAllSessionsForProject(1),
        ).thenAnswer((_) async => sessions);
        await sessionStore.loadSessions(1);

        var notificationCount = 0;
        sessionStore.addListener(() => notificationCount++);

        final updatedSession = Session(
          id: 1,
          projectId: 1,
          name: 'Updated',
          duration: Duration.zero,
          gpsPoints: 0,
        );
        when(mockDbHelper.updateSession(any)).thenAnswer((_) async => 1);

        await sessionStore.updateSession(updatedSession);

        expect(notificationCount, greaterThanOrEqualTo(1));
      });

      test('notifies listeners on deleteSession', () async {
        // Setup
        final sessions = [
          Session(
            id: 1,
            projectId: 1,
            name: 'Session',
            duration: Duration.zero,
            gpsPoints: 0,
          ),
        ];
        when(
          mockDbHelper.readAllSessionsForProject(1),
        ).thenAnswer((_) async => sessions);
        await sessionStore.loadSessions(1);

        var notificationCount = 0;
        sessionStore.addListener(() => notificationCount++);

        when(mockDbHelper.deleteSession(1)).thenAnswer((_) async => 1);

        await sessionStore.deleteSession(projectId: 1, sessionId: 1);

        expect(notificationCount, greaterThanOrEqualTo(1));
      });

      test('notifies listeners on clearError', () async {
        // Create an error
        when(
          mockDbHelper.readAllSessionsForProject(1),
        ).thenThrow(Exception('Error'));
        try {
          await sessionStore.loadSessions(1);
        } catch (_) {}

        var notificationCount = 0;
        sessionStore.addListener(() => notificationCount++);

        sessionStore.clearError(1);

        expect(notificationCount, 1);
      });

      test('does not notify on clearError when no error exists', () {
        var notificationCount = 0;
        sessionStore.addListener(() => notificationCount++);

        sessionStore.clearError(1);

        expect(notificationCount, 0);
      });

      test('notifies listeners on clearCache', () async {
        var notificationCount = 0;
        sessionStore.addListener(() => notificationCount++);

        sessionStore.clearCache();

        expect(notificationCount, 1);
      });
    });

    test('uses default DatabaseHelper.instance when not provided', () {
      final store = SessionStore();
      // Should not crash and should be initialized
      expect(store.sessionsForProject(1), isEmpty);
      expect(store.isLoading(1), false);
      expect(store.errorForProject(1), isNull);
    });
  });
}
