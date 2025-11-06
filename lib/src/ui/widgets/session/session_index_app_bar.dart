import 'package:flutter/material.dart';
import 'package:roadmindphone/src/ui/widgets/session/session_actions_menu.dart';

class SessionIndexAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  final void Function(String value) onMenuSelected;
  final Color? backgroundColor;

  const SessionIndexAppBar({
    Key? key,
    required this.title,
    required this.onMenuSelected,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      backgroundColor:
          backgroundColor ?? Theme.of(context).colorScheme.inversePrimary,
      actions: <Widget>[SessionActionsMenu(onSelected: onMenuSelected)],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
