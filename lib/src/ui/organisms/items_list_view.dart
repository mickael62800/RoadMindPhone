
import 'package:flutter/material.dart';
import 'package:roadmindphone/src/ui/molecules/molecules.dart';

class ItemsListView<T> extends StatelessWidget {
  final List<T> items;
  final String Function(T item) titleBuilder;
  final String Function(T item) subtitleBuilder;
  final void Function(T item)? onTapBuilder;

  const ItemsListView({
    super.key,
    required this.items,
    required this.titleBuilder,
    required this.subtitleBuilder,
    this.onTapBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        if (orientation == Orientation.landscape) {
          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 4,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ListItemCard(
                title: titleBuilder(item),
                subtitle: subtitleBuilder(item),
                onTap: onTapBuilder != null ? () => onTapBuilder!(item) : null,
              );
            },
          );
        } else {
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ListItemCard(
                title: titleBuilder(item),
                subtitle: subtitleBuilder(item),
                onTap: onTapBuilder != null ? () => onTapBuilder!(item) : null,
              );
            },
          );
        }
      },
    );
  }
}
