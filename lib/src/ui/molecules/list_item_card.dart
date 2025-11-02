
import 'package:flutter/material.dart';
import 'package:roadmindphone/src/ui/atoms/atoms.dart';

class ListItemCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const ListItemCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: ListTile(
        title: TitleText(text: title),
        subtitle: SubtitleText(text: subtitle),
        onTap: onTap,
      ),
    );
  }
}
