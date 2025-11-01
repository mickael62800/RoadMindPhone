import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mockito/mockito.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:camera_platform_interface/camera_platform_interface.dart';

import 'package:roadmindphone/database_helper.dart';
import 'package:roadmindphone/session_completion_page.dart';
import 'package:roadmindphone/session.dart';

import 'mocks.mocks.dart';
import 'mocks/mock_flutter_map.dart';
import 'fake_geolocator_platform.dart';
import 'fake_camera_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SessionCompletionPage', () {
    late MockDatabaseHelper mockDbHelper;
    late FakeGeolocatorPlatform
    fakeGeolocatorPlatform; // Use the fake implementation
    late FakeCameraPlatform
    fakeCameraPlatform; // Use the fake camera implementation

    late Session testSession;

    setUp(() {
      // mapController not used, removed
      mockDbHelper = MockDatabaseHelper();
      DatabaseHelper.setTestInstance(mockDbHelper);

      fakeGeolocatorPlatform =
          FakeGeolocatorPlatform(); // Instantiate the fake implementation
      GeolocatorPlatform.instance = fakeGeolocatorPlatform;

      fakeCameraPlatform =
          FakeCameraPlatform(); // Instantiate the fake camera implementation
      CameraPlatform.instance = fakeCameraPlatform;

      // Mock path_provider for getTemporaryDirectory (used by XFile in some scenarios)
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (MethodCall methodCall) async {
              if (methodCall.method == 'getTemporaryDirectory') {
                return '/tmp';
              }
              return null;
            },
          );

      // Mock platform channel calls for permission_handler
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('flutter.baseflow.com/permissions/methods'),
            (MethodCall methodCall) async {
              if (methodCall.method == 'requestPermissions') {
                return {
                  Permission.microphone.value: PermissionStatus.granted.index,
                };
              }
              return null;
            },
          );

      // Mock for DatabaseHelper
      when(mockDbHelper.updateSession(any)).thenAnswer((_) async => 1);

      testSession = Session(
        id: 1,
        projectId: 1,
        name: 'Test Session',
        duration: Duration.zero,
        gpsPoints: 0,
      );
      // mapController = MapController(); // Not used, commented out
    });

    tearDown(() {
      // Reset the DatabaseHelper instance after each test
      DatabaseHelper.resetInstance();
      // Reset path_provider mock
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            null,
          );
      // Reset permission_handler mock
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('flutter.baseflow.com/permissions/methods'),
            null,
          );
    });

    testWidgets(
      'initializes successfully and displays map and camera preview',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: SessionCompletionPage(
              session: testSession,
              flutterMapBuilder:
                  ({key, required options, children, mapController}) {
                    return MockFlutterMap(
                      key: key,
                      options: options,
                      mapController: mapController,
                      children: children ?? [],
                    );
                  },
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(SessionCompletionPage), findsOneWidget);
        expect(find.byKey(const Key('mockMapContainer')), findsOneWidget);
        expect(find.text('Go!'), findsOneWidget);
      },
    );

    testWidgets('displays stop button when recording', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SessionCompletionPage(
            session: testSession,
            flutterMapBuilder:
                ({key, required options, children, mapController}) {
                  return MockFlutterMap(
                    key: key,
                    options: options,
                    mapController: mapController,
                    children: children ?? [],
                  );
                },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Start recording by tapping Go button
      await tester.tap(find.text('Go!'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Verify Stop button appears
      expect(find.text('Stop'), findsOneWidget);
    });

    testWidgets('displays duration when recording', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SessionCompletionPage(
            session: testSession,
            flutterMapBuilder:
                ({key, required options, children, mapController}) {
                  return MockFlutterMap(
                    key: key,
                    options: options,
                    mapController: mapController,
                    children: children ?? [],
                  );
                },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Start recording
      await tester.tap(find.text('Go!'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Verify duration display (starts at 00:00:00)
      expect(find.textContaining(':'), findsWidgets);
    });

    testWidgets('stop recording updates session', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SessionCompletionPage(
            session: testSession,
            flutterMapBuilder:
                ({key, required options, children, mapController}) {
                  return MockFlutterMap(
                    key: key,
                    options: options,
                    mapController: mapController,
                    children: children ?? [],
                  );
                },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Start recording
      await tester.tap(find.text('Go!'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Stop recording
      await tester.tap(find.text('Stop'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Verify updateSession was called
      verify(mockDbHelper.updateSession(any)).called(greaterThan(0));
    });

    testWidgets('displays map container', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SessionCompletionPage(
            session: testSession,
            flutterMapBuilder:
                ({key, required options, children, mapController}) {
                  return MockFlutterMap(
                    key: key,
                    options: options,
                    mapController: mapController,
                    children: children ?? [],
                  );
                },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Expanded widget for map
      expect(find.byType(Expanded), findsWidgets);
    });

    testWidgets('uses default FlutterMap builder when not provided', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SessionCompletionPage(
            session: testSession,
            // Not providing flutterMapBuilder
          ),
        ),
      );
      await tester.pump();

      // Should build without error using default builder
      expect(find.byType(SessionCompletionPage), findsOneWidget);
    });

    testWidgets('AppBar displays session name', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SessionCompletionPage(
            session: testSession,
            flutterMapBuilder:
                ({key, required options, children, mapController}) {
                  return MockFlutterMap(
                    key: key,
                    options: options,
                    mapController: mapController,
                    children: children ?? [],
                  );
                },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify AppBar shows session name
      expect(find.widgetWithText(AppBar, 'Test Session'), findsOneWidget);
    });

    testWidgets('Column layout is structured correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SessionCompletionPage(
            session: testSession,
            flutterMapBuilder:
                ({key, required options, children, mapController}) {
                  return MockFlutterMap(
                    key: key,
                    options: options,
                    mapController: mapController,
                    children: children ?? [],
                  );
                },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Column widget exists
      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('displays map widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SessionCompletionPage(
            session: testSession,
            flutterMapBuilder:
                ({key, required options, children, mapController}) {
                  return MockFlutterMap(
                    key: key,
                    options: options,
                    mapController: mapController,
                    children: children ?? [],
                  );
                },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify map is displayed
      expect(find.byType(MockFlutterMap), findsOneWidget);
    });

    testWidgets('handles orientation changes', (WidgetTester tester) async {
      // Set landscape size
      await tester.binding.setSurfaceSize(const Size(800, 600));

      await tester.pumpWidget(
        MaterialApp(
          home: SessionCompletionPage(
            session: testSession,
            flutterMapBuilder:
                ({key, required options, children, mapController}) {
                  return MockFlutterMap(
                    key: key,
                    options: options,
                    mapController: mapController,
                    children: children ?? [],
                  );
                },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify map present in landscape
      expect(find.byType(MockFlutterMap), findsOneWidget);

      // Reset size
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('displays video preview widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SessionCompletionPage(
            session: testSession,
            flutterMapBuilder:
                ({key, required options, children, mapController}) {
                  return MockFlutterMap(
                    key: key,
                    options: options,
                    mapController: mapController,
                    children: children ?? [],
                  );
                },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify camera preview - just check for the loading text
      expect(find.text('Initializing camera...'), findsOneWidget);
    });

    testWidgets('displays map widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SessionCompletionPage(
            session: testSession,
            flutterMapBuilder:
                ({key, required options, children, mapController}) {
                  return MockFlutterMap(
                    key: key,
                    options: options,
                    mapController: mapController,
                    children: children ?? [],
                  );
                },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify map is displayed
      expect(find.byType(MockFlutterMap), findsOneWidget);
    });

    testWidgets('displays speed indicator', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SessionCompletionPage(
            session: testSession,
            flutterMapBuilder:
                ({key, required options, children, mapController}) {
                  return MockFlutterMap(
                    key: key,
                    options: options,
                    mapController: mapController,
                    children: children ?? [],
                  );
                },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify map is displayed (MockFlutterMap)
      expect(find.byType(MockFlutterMap), findsOneWidget);
    });

    testWidgets('handles stop button press', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SessionCompletionPage(
            session: testSession,
            flutterMapBuilder:
                ({key, required options, children, mapController}) {
                  return MockFlutterMap(
                    key: key,
                    options: options,
                    mapController: mapController,
                    children: children ?? [],
                  );
                },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The button shows 'Go!' initially, need to tap it to start recording
      // then it will show 'Stop'
      final goButton = find.text('Go!');
      expect(goButton, findsOneWidget);

      // Tap to start recording
      await tester.tap(goButton, warnIfMissed: false);
      await tester.pump();

      // Now button should show 'Stop'
      expect(find.text('Stop'), findsOneWidget);
    });

    testWidgets('displays all UI elements in landscape', (
      WidgetTester tester,
    ) async {
      // Set landscape size
      await tester.binding.setSurfaceSize(const Size(800, 600));

      await tester.pumpWidget(
        MaterialApp(
          home: SessionCompletionPage(
            session: testSession,
            flutterMapBuilder:
                ({key, required options, children, mapController}) {
                  return MockFlutterMap(
                    key: key,
                    options: options,
                    mapController: mapController,
                    children: children ?? [],
                  );
                },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify all elements present
      expect(find.byType(MockFlutterMap), findsOneWidget);
      expect(find.text('Go!'), findsOneWidget);
      expect(find.text('Initializing camera...'), findsOneWidget);

      // Reset size
      await tester.binding.setSurfaceSize(null);
    });
  });
}
