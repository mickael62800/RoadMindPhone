import 'package:flutter/material.dart';
import 'package:roadmindphone/src/ui/molecules/molecules.dart';

class ItemsListView<T> extends StatelessWidget {
  final List<T> items;
  final String Function(T item) titleBuilder;
  final String Function(T item) subtitleBuilder;
  final void Function(T item)? onTapBuilder;
  final Widget? Function(T item)? trailingBuilder;

  const ItemsListView({
    super.key,
    required this.items,
    required this.titleBuilder,
    required this.subtitleBuilder,
    this.onTapBuilder,
    this.trailingBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return ListItemCard(
          title: titleBuilder(item),
          subtitle: subtitleBuilder(item),
          onTap: onTapBuilder != null ? () => onTapBuilder!(item) : null,
          trailing: trailingBuilder != null ? trailingBuilder!(item) : null,
        );
      },
    );
  }
}
