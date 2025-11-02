import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roadmindphone/src/ui/molecules/rename_dialog.dart';
import 'package:roadmindphone/src/ui/atoms/atoms.dart';

void main() {
  group('RenameDialog Molecule Tests', () {
    testWidgets('displays dialog with correct title and hint', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    await showRenameDialog(
                      context: context,
                      title: 'Renommer le projet',
                      hintText: 'Nouveau titre du projet',
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify dialog content
      expect(find.text('Renommer le projet'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('ANNULER'), findsOneWidget);
      expect(find.text('RENOMMER'), findsOneWidget);

      // Verify hint text
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.decoration?.hintText, 'Nouveau titre du projet');
    });

    testWidgets('displays initial value when provided', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    await showRenameDialog(
                      context: context,
                      title: 'Renommer',
                      hintText: 'Nouveau nom',
                      initialValue: 'Valeur initiale',
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify initial value is in the TextField
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, 'Valeur initiale');
    });

    testWidgets('returns null when cancel button is pressed', (
      WidgetTester tester,
    ) async {
      String? result = 'not null';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    result = await showRenameDialog(
                      context: context,
                      title: 'Renommer',
                      hintText: 'Nouveau nom',
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Tap cancel
      await tester.tap(find.text('ANNULER'));
      await tester.pumpAndSettle();

      // Verify result is null
      expect(result, isNull);
    });

    testWidgets('returns entered text when rename button is pressed', (
      WidgetTester tester,
    ) async {
      String? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    result = await showRenameDialog(
                      context: context,
                      title: 'Renommer',
                      hintText: 'Nouveau nom',
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Enter text
      await tester.enterText(find.byType(TextField), 'Nouveau nom saisi');
      await tester.pumpAndSettle();

      // Tap rename
      await tester.tap(find.text('RENOMMER'));
      await tester.pumpAndSettle();

      // Verify result
      expect(result, 'Nouveau nom saisi');
    });

    testWidgets('returns text when submitting via keyboard', (
      WidgetTester tester,
    ) async {
      String? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    result = await showRenameDialog(
                      context: context,
                      title: 'Renommer',
                      hintText: 'Nouveau nom',
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Enter text and submit
      await tester.enterText(find.byType(TextField), 'Soumis par Enter');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Verify result
      expect(result, 'Soumis par Enter');
    });

    testWidgets('returns empty string if no text entered', (
      WidgetTester tester,
    ) async {
      String? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    result = await showRenameDialog(
                      context: context,
                      title: 'Renommer',
                      hintText: 'Nouveau nom',
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Don't enter any text, just tap rename
      await tester.tap(find.text('RENOMMER'));
      await tester.pumpAndSettle();

      // Verify result is empty string
      expect(result, '');
    });

    testWidgets('uses TitleText atom for title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    await showRenameDialog(
                      context: context,
                      title: 'Test Title',
                      hintText: 'Hint',
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify TitleText is used
      expect(find.byType(TitleText), findsOneWidget);
      final titleText = tester.widget<TitleText>(find.byType(TitleText));
      expect(titleText.text, 'Test Title');
    });

    testWidgets('uses ActionButton atoms for buttons', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    await showRenameDialog(
                      context: context,
                      title: 'Test',
                      hintText: 'Hint',
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify ActionButtons are used
      expect(find.byType(ActionButton), findsNWidgets(2));

      // Verify button texts
      final buttons = tester.widgetList<ActionButton>(
        find.byType(ActionButton),
      );
      final buttonTexts = buttons.map((b) => b.text).toList();
      expect(buttonTexts, containsAll(['ANNULER', 'RENOMMER']));
    });

    testWidgets('TextField has autofocus enabled', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    await showRenameDialog(
                      context: context,
                      title: 'Test',
                      hintText: 'Hint',
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify autofocus
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.autofocus, true);
    });

    testWidgets('modifying initial value and renaming returns modified text', (
      WidgetTester tester,
    ) async {
      String? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    result = await showRenameDialog(
                      context: context,
                      title: 'Renommer',
                      hintText: 'Nouveau nom',
                      initialValue: 'Ancien nom',
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify initial value
      expect(find.text('Ancien nom'), findsOneWidget);

      // Modify text
      await tester.enterText(find.byType(TextField), 'Nom modifié');
      await tester.pumpAndSettle();

      // Tap rename
      await tester.tap(find.text('RENOMMER'));
      await tester.pumpAndSettle();

      // Verify result
      expect(result, 'Nom modifié');
    });

    testWidgets('dialog is dismissible by tapping outside', (
      WidgetTester tester,
    ) async {
      String? result = 'not null';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    result = await showRenameDialog(
                      context: context,
                      title: 'Test',
                      hintText: 'Hint',
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Tap outside dialog (on the barrier)
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // Verify result is null
      expect(result, isNull);
    });

    testWidgets('works with different titles and hints', (
      WidgetTester tester,
    ) async {
      const testCases = [
        ('Renommer le projet', 'Nouveau titre du projet'),
        ('Renommer la session', 'Nouveau nom de la session'),
        ('Modifier', 'Nouvelle valeur'),
      ];

      for (final testCase in testCases) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () async {
                      await showRenameDialog(
                        context: context,
                        title: testCase.$1,
                        hintText: testCase.$2,
                      );
                    },
                    child: const Text('Show Dialog'),
                  );
                },
              ),
            ),
          ),
        );

        // Open dialog
        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Verify title and hint
        expect(find.text(testCase.$1), findsOneWidget);
        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.decoration?.hintText, testCase.$2);

        // Close dialog
        await tester.tap(find.text('ANNULER'));
        await tester.pumpAndSettle();
      }
    });
  });
}
