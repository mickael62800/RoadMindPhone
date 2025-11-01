import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roadmindphone/settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsPage', () {
    setUp(() {
      // Mock the platform channel for shared_preferences
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/shared_preferences'),
            (MethodCall methodCall) async {
              if (methodCall.method == 'getAll') {
                return <String, Object>{};
              }
              return null;
            },
          );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/shared_preferences'),
            null,
          );
    });

    testWidgets('loads default settings when no settings are saved', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({}); // No saved values

      await tester.pumpWidget(const MaterialApp(home: SettingsPage()));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextField, 'localhost'), findsOneWidget);
      expect(find.widgetWithText(TextField, '5439'), findsOneWidget);
    });

    testWidgets('loads saved settings', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'db_server_address': '192.168.1.1',
        'db_port': '8080',
      });

      await tester.pumpWidget(const MaterialApp(home: SettingsPage()));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextField, '192.168.1.1'), findsOneWidget);
      expect(find.widgetWithText(TextField, '8080'), findsOneWidget);
    });

    testWidgets('saves new settings', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({}); // Start with no saved values

      await tester.pumpWidget(const MaterialApp(home: SettingsPage()));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byWidgetPredicate(
          (widget) =>
              widget is TextField &&
              widget.decoration?.labelText == 'Database Server Address',
        ),
        '192.168.1.100',
      );
      await tester.enterText(
        find.byWidgetPredicate(
          (widget) =>
              widget is TextField &&
              widget.decoration?.labelText == 'Database Port',
        ),
        '9000',
      );
      await tester.tap(find.text('Sauver'));
      await tester.pump(); // Pump to show the SnackBar

      expect(find.text('Settings saved!'), findsOneWidget);
      await tester.pumpAndSettle(); // Pump to allow navigation to complete
    });

    testWidgets('navigates back after saving settings', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({}); // Start with no saved values

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              return ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsPage(),
                    ),
                  );
                },
                child: const Text('Go to Settings'),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Go to Settings'));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsPage), findsOneWidget);

      await tester.enterText(
        find.byWidgetPredicate(
          (widget) =>
              widget is TextField &&
              widget.decoration?.labelText == 'Database Server Address',
        ),
        '192.168.1.100',
      );
      await tester.enterText(
        find.byWidgetPredicate(
          (widget) =>
              widget is TextField &&
              widget.decoration?.labelText == 'Database Port',
        ),
        '9000',
      );
      await tester.tap(find.text('Sauver'));
      await tester.pumpAndSettle();

      expect(
        find.byType(SettingsPage),
        findsNothing,
      ); // Should have navigated back
    });
  });
}
