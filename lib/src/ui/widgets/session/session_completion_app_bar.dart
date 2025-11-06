import 'package:flutter/material.dart';

class SessionCompletionAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  final String info;
  final Color? backgroundColor;

  const SessionCompletionAppBar({
    Key? key,
    required this.title,
    required this.info,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      backgroundColor:
          backgroundColor ?? Theme.of(context).colorScheme.inversePrimary,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(30.0),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(info, style: const TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 30.0);
}
