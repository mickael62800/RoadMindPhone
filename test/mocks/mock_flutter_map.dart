import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'; // Import for MapOptions and MapController

class MockFlutterMap extends StatelessWidget {
  final MapOptions options;
  final List<Widget> children;
  final MapController? mapController;

  const MockFlutterMap({
    super.key,
    required this.options,
    this.children = const [],
    this.mapController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('mockMapContainer'),
      width: double.infinity,
      height: double.infinity,
      color: Colors.blueGrey[100],
      alignment: Alignment.center,
      child: const Text('Mock Map Rendered'),
    );
  }
}
