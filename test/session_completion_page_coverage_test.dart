import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:roadmindphone/session_completion_page.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart';

import 'fake_geolocator_platform.dart';
import 'fake_permission_platform.dart';

import 'mocks.mocks.dart';

void main() {
  group('SessionCompletionPage Coverage Tests', () {
    late MockSession mockSession;
    late FakeGeolocatorPlatform fakeGeolocatorPlatform;
    // late fcp.FakeCameraPlatform fakeCameraPlatform; // Not used
    late FakePermissionPlatform fakePermissionPlatform;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      mockSession = MockSession();
      fakeGeolocatorPlatform = FakeGeolocatorPlatform();
      // fakeCameraPlatform = fcp.FakeCameraPlatform(); // Not used
      fakePermissionPlatform = FakePermissionPlatform();

      when(mockSession.name).thenReturn('Test Session');
      when(mockSession.id).thenReturn(1);

      GeolocatorPlatform.instance = fakeGeolocatorPlatform;
      PermissionHandlerPlatform.instance = fakePermissionPlatform;

      // Default state for successful location and camera initialization
      fakeGeolocatorPlatform.setMockLocationServiceEnabled(true);
      fakeGeolocatorPlatform.setMockPermission(LocationPermission.whileInUse);
      fakeGeolocatorPlatform.setMockPosition(
        Position(
          latitude: 0.0,
          longitude: 0.0,
          timestamp: DateTime.now(),
          accuracy: 0.0,
          altitude: 0.0,
          heading: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
          altitudeAccuracy: 0.0,
          headingAccuracy: 0.0,
        ),
      );

      // Default permission status for microphone
      fakePermissionPlatform.setMicrophonePermissionStatus(
        PermissionStatus.granted,
      );
    });

    testWidgets('defaultFlutterMapBuilder builds FlutterMap correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: SessionCompletionPage(session: mockSession)),
      );

      await tester.pumpAndSettle(); // Allow _determinePosition to complete

      expect(find.byType(FlutterMap), findsOneWidget);
    });
  });
}
