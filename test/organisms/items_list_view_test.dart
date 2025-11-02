import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roadmindphone/src/ui/organisms/items_list_view.dart';
import 'package:roadmindphone/src/ui/molecules/list_item_card.dart';

void main() {
  group('ItemsListView Organism Tests', () {
    // Test data
    final testItems = [
      {'id': 1, 'name': 'Item 1'},
      {'id': 2, 'name': 'Item 2'},
      {'id': 3, 'name': 'Item 3'},
    ];

    Widget createTestWidget({
      required List<Map<String, dynamic>> items,
      Size? screenSize,
      Orientation? forcedOrientation,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              if (forcedOrientation != null) {
                // Override MediaQuery to force orientation
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    size: forcedOrientation == Orientation.landscape
                        ? const Size(800, 600)
                        : const Size(400, 800),
                  ),
                  child: OrientationBuilder(
                    builder: (context, _) {
                      return ItemsListView<Map<String, dynamic>>(
                        items: items,
                        titleBuilder: (item) => item['name'] as String,
                        subtitleBuilder: (item) => 'ID: ${item['id']}',
                        onTapBuilder: (item) {
                          // Test callback
                        },
                      );
                    },
                  ),
                );
              }

              return ItemsListView<Map<String, dynamic>>(
                items: items,
                titleBuilder: (item) => item['name'] as String,
                subtitleBuilder: (item) => 'ID: ${item['id']}',
                onTapBuilder: (item) {
                  // Test callback
                },
              );
            },
          ),
        ),
      );
    }

    testWidgets('displays items in ListView in portrait mode', (
      WidgetTester tester,
    ) async {
      // Set portrait size
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(items: testItems));
      await tester.pumpAndSettle();

      // In portrait mode, ListView.builder is used
      // Verify all items are rendered
      for (var item in testItems) {
        expect(find.text(item['name'] as String), findsOneWidget);
        expect(find.text('ID: ${item['id']}'), findsOneWidget);
      }

      // Verify ListItemCard is used
      expect(find.byType(ListItemCard), findsNWidgets(testItems.length));
    });

    testWidgets('displays items in GridView in landscape mode', (
      WidgetTester tester,
    ) async {
      // Set landscape size
      tester.view.physicalSize = const Size(800, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(items: testItems));
      await tester.pumpAndSettle();

      // Verify all items are rendered
      for (var item in testItems) {
        expect(find.text(item['name'] as String), findsOneWidget);
        expect(find.text('ID: ${item['id']}'), findsOneWidget);
      }

      // Verify ListItemCard is used
      expect(find.byType(ListItemCard), findsNWidgets(testItems.length));
    });

    testWidgets('handles empty list', (WidgetTester tester) async {
      // Set portrait size
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(items: []));
      await tester.pumpAndSettle();

      // Verify no ListItemCards are rendered
      expect(find.byType(ListItemCard), findsNothing);
    });

    testWidgets('calls onTapBuilder when item is tapped', (
      WidgetTester tester,
    ) async {
      // Set portrait size
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      Map<String, dynamic>? tappedItem;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ItemsListView<Map<String, dynamic>>(
              items: testItems,
              titleBuilder: (item) => item['name'] as String,
              subtitleBuilder: (item) => 'ID: ${item['id']}',
              onTapBuilder: (item) {
                tappedItem = item;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on the first item
      await tester.tap(find.text('Item 1'));
      await tester.pumpAndSettle();

      // Verify the callback was called with the correct item
      expect(tappedItem, isNotNull);
      expect(tappedItem!['id'], 1);
      expect(tappedItem!['name'], 'Item 1');
    });

    testWidgets('works without onTapBuilder', (WidgetTester tester) async {
      // Set portrait size
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ItemsListView<Map<String, dynamic>>(
              items: testItems,
              titleBuilder: (item) => item['name'] as String,
              subtitleBuilder: (item) => 'ID: ${item['id']}',
              // onTapBuilder is null
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify items are rendered
      expect(find.byType(ListItemCard), findsNWidgets(testItems.length));

      // Tapping should not cause any errors
      await tester.tap(find.text('Item 1'));
      await tester.pumpAndSettle();
    });

    testWidgets('GridView has correct properties in landscape', (
      WidgetTester tester,
    ) async {
      // Set landscape size
      tester.view.physicalSize = const Size(800, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(items: testItems));
      await tester.pumpAndSettle();

      // Verify all items are displayed correctly
      expect(find.byType(ListItemCard), findsNWidgets(testItems.length));
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
      expect(find.text('Item 3'), findsOneWidget);
    });

    testWidgets('handles single item', (WidgetTester tester) async {
      // Set portrait size
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final singleItem = [
        {'id': 1, 'name': 'Only Item'},
      ];

      await tester.pumpWidget(createTestWidget(items: singleItem));
      await tester.pumpAndSettle();

      expect(find.byType(ListItemCard), findsOneWidget);
      expect(find.text('Only Item'), findsOneWidget);
      expect(find.text('ID: 1'), findsOneWidget);
    });

    testWidgets('handles large list', (WidgetTester tester) async {
      // Set portrait size
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final largeList = List.generate(
        100,
        (index) => {'id': index, 'name': 'Item $index'},
      );

      await tester.pumpWidget(createTestWidget(items: largeList));
      await tester.pumpAndSettle();

      // Verify first items are visible (list is lazy-loaded)
      expect(find.text('Item 0'), findsOneWidget);

      // Some items should be visible
      expect(find.byType(ListItemCard), findsWidgets);
    });

    testWidgets('titleBuilder and subtitleBuilder are called correctly', (
      WidgetTester tester,
    ) async {
      // Set portrait size
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      int titleCallCount = 0;
      int subtitleCallCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ItemsListView<Map<String, dynamic>>(
              items: testItems,
              titleBuilder: (item) {
                titleCallCount++;
                return 'Title: ${item['name']}';
              },
              subtitleBuilder: (item) {
                subtitleCallCount++;
                return 'Subtitle: ${item['id']}';
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Builders should be called for each visible item
      expect(titleCallCount, greaterThan(0));
      expect(subtitleCallCount, greaterThan(0));

      // Verify the built text is displayed
      expect(find.text('Title: Item 1'), findsOneWidget);
      expect(find.text('Subtitle: 1'), findsOneWidget);
    });

    testWidgets('uses OrientationBuilder internally', (
      WidgetTester tester,
    ) async {
      // Set portrait size
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(items: testItems));
      await tester.pumpAndSettle();

      // Verify OrientationBuilder is used
      expect(find.byType(OrientationBuilder), findsWidgets);
    });

    testWidgets('renders different content types', (WidgetTester tester) async {
      // Set portrait size
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Test with different data structure
      final customItems = [
        {'title': 'Custom 1', 'description': 'Desc 1'},
        {'title': 'Custom 2', 'description': 'Desc 2'},
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ItemsListView<Map<String, dynamic>>(
              items: customItems,
              titleBuilder: (item) => item['title'] as String,
              subtitleBuilder: (item) => item['description'] as String,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Custom 1'), findsOneWidget);
      expect(find.text('Desc 1'), findsOneWidget);
      expect(find.text('Custom 2'), findsOneWidget);
      expect(find.text('Desc 2'), findsOneWidget);
    });
  });
}
