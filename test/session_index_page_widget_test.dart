import 'package:flutter/material.dart';
import 'package:roadmindphone/main.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roadmindphone/database_helper.dart';
import 'package:roadmindphone/project_index_page.dart';
import 'package:roadmindphone/session_index_page.dart';
import 'package:mockito/mockito.dart';
import 'package:roadmindphone/session_gps_point.dart';
import 'mocks.mocks.dart';

void main() {
  group('SessionIndexPage Widget Tests', () {
    late MockDatabaseHelper mockDbHelper;
    late Project project;
    late Session sessionWithGps;
    late Session sessionWithoutGps;

    setUp(() {
      mockDbHelper = MockDatabaseHelper();
      DatabaseHelper.setTestInstance(mockDbHelper);

      project = Project(id: 1, title: 'Test Project');

      sessionWithGps = Session(
        id: 1,
        projectId: project.id!,
        name: 'Session with GPS',
        duration: const Duration(minutes: 30),
        gpsPoints: 50,
        gpsData: [
          SessionGpsPoint(sessionId: 1, latitude: 48.8566, longitude: 2.3522, speed: 5.0, timestamp: DateTime.now(), videoTimestampMs: 0),
          SessionGpsPoint(sessionId: 1, latitude: 48.8580, longitude: 2.2945, speed: 10.0, timestamp: DateTime.now().add(const Duration(minutes: 1)), videoTimestampMs: 0),
        ],
      );

      sessionWithoutGps = Session(
        id: 2,
        projectId: project.id!,
        name: 'Session without GPS',
        duration: const Duration(minutes: 10),
        gpsPoints: 0,
      );

      when(mockDbHelper.updateSession(any))
          .thenAnswer((invocation) async => 1);
      when(mockDbHelper.deleteSession(any))
          .thenAnswer((_) async => 1);
      when(mockDbHelper.readProject(project.id!))
          .thenAnswer((_) async => project);
      when(mockDbHelper.readSession(sessionWithGps.id!))
          .thenAnswer((_) async => sessionWithGps);
      when(mockDbHelper.readSession(sessionWithoutGps.id!))
          .thenAnswer((_) async => sessionWithoutGps);
    });

    tearDown(() {
      // Reset the DatabaseHelper instance after each test
      DatabaseHelper.resetInstance();
    });

    testWidgets('Displays session details correctly with GPS data', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: SessionIndexPage(session: sessionWithGps),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Session with GPS'), findsOneWidget);
      expect(find.text('Points GPS'), findsOneWidget);
      expect(find.text('50'), findsOneWidget);
      expect(find.text('Durée'), findsOneWidget);
      expect(find.text('Vitesse Moyenne'), findsOneWidget);
      expect(find.textContaining('km/h'), findsOneWidget);
      expect(find.text('Distance'), findsOneWidget);
      expect(find.textContaining('km'), findsOneWidget);
    });

    testWidgets('Displays session details correctly without GPS data', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: SessionIndexPage(session: sessionWithoutGps),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Session without GPS'), findsOneWidget);
      expect(find.text('Points GPS'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('Durée'), findsOneWidget);
      expect(find.text('00:10:00'), findsOneWidget);
      expect(find.text('Vitesse Moyenne'), findsOneWidget);
      expect(find.textContaining('km/h'), findsOneWidget);
      expect(find.text('Distance'), findsOneWidget);
      expect(find.textContaining('km'), findsOneWidget);
      expect(find.text('En attente de données'), findsOneWidget);
    });

    testWidgets('Renames a session', (WidgetTester tester) async {
      when(mockDbHelper.updateSession(any))
          .thenAnswer((_) async => 1);

      await tester.pumpWidget(MaterialApp(
        home: SessionIndexPage(session: sessionWithGps),
      ));
      await tester.pumpAndSettle();

      // Open the popup menu
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      // Tap on 'Editer'
      await tester.tap(find.text('Editer'));
      await tester.pumpAndSettle();

      // Verify the rename dialog is shown
      expect(find.text('Renommer la session'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Renamed Session');
      await tester.tap(find.text('RENOMMER'));
      await tester.pumpAndSettle();

      expect(find.text('Renamed Session'), findsOneWidget);
      expect(find.text('Session with GPS'), findsNothing);
    });

    testWidgets('Deletes a session', (WidgetTester tester) async {
      when(mockDbHelper.deleteSession(sessionWithGps.id!))
          .thenAnswer((_) async => 1);
      when(mockDbHelper.readAllSessionsForProject(project.id!))
          .thenAnswer((_) async => []); // After deletion, no sessions

      await tester.pumpWidget(MaterialApp(
        home: SessionIndexPage(session: sessionWithGps),
      ));
      await tester.pumpAndSettle();

      // Open the popup menu
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      // Tap on 'Supprimer'
      await tester.tap(find.text('Supprimer'));
      await tester.pumpAndSettle();

      // Confirm deletion in the dialog
      expect(find.text('Supprimer la session'), findsOneWidget);
      await tester.tap(find.text('SUPPRIMER'));
      await tester.pumpAndSettle();

      // Verify navigation back to ProjectIndexPage and session is gone
      expect(find.text('Test Project'), findsOneWidget); // Back on ProjectIndexPage
      expect(find.text('Session with GPS'), findsNothing); // Session should be deleted
    });
  });
}
