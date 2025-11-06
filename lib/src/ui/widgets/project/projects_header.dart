import 'package:flutter/material.dart';

class ProjectsHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onAdd;
  final ValueChanged<String>? onSearch;
  final bool showSearch;

  const ProjectsHeader({
    Key? key,
    required this.title,
    this.onAdd,
    this.onSearch,
    this.showSearch = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: showSearch
                ? TextField(
                    decoration: const InputDecoration(
                      hintText: 'Rechercher...',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                    ),
                    onChanged: onSearch,
                  )
                : Text(title, style: Theme.of(context).textTheme.headlineSmall),
          ),
          if (onAdd != null)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Ajouter',
              onPressed: onAdd,
            ),
        ],
      ),
    );
  }
}
