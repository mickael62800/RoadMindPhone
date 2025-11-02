import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../stores/project_store.dart';
import '../main.dart';

/// Exemple d'utilisation du ProjectStore avec Provider
///
/// Cette page montre comment intégrer le ProjectStore dans une interface
class ProjectStoreExample extends StatefulWidget {
  const ProjectStoreExample({super.key});

  @override
  State<ProjectStoreExample> createState() => _ProjectStoreExampleState();
}

class _ProjectStoreExampleState extends State<ProjectStoreExample> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Charger les projets au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProjectStore>().loadProjects();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _showCreateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouveau Projet'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Titre'),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ANNULER'),
          ),
          TextButton(
            onPressed: () async {
              if (_titleController.text.isNotEmpty) {
                try {
                  await context.read<ProjectStore>().createProject(
                    _titleController.text,
                    description: _descriptionController.text.isEmpty
                        ? null
                        : _descriptionController.text,
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    _titleController.clear();
                    _descriptionController.clear();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Projet créé avec succès')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                  }
                }
              }
            },
            child: const Text('CRÉER'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, Project project) {
    _titleController.text = project.title;
    _descriptionController.text = project.description ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le Projet'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Titre'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ANNULER'),
          ),
          TextButton(
            onPressed: () async {
              if (_titleController.text.isNotEmpty) {
                try {
                  final updated = Project(
                    id: project.id,
                    title: _titleController.text,
                    description: _descriptionController.text.isEmpty
                        ? null
                        : _descriptionController.text,
                  );
                  await context.read<ProjectStore>().updateProject(updated);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Projet mis à jour')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                  }
                }
              }
            },
            child: const Text('MODIFIER'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Project project) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le Projet'),
        content: Text('Voulez-vous vraiment supprimer "${project.title}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ANNULER'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await context.read<ProjectStore>().deleteProject(project.id!);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Projet supprimé')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('SUPPRIMER'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ProjectStore Example'),
        actions: [
          // Bouton pour rafraîchir tous les projets
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<ProjectStore>().loadProjects(),
          ),
        ],
      ),
      body: Consumer<ProjectStore>(
        builder: (context, store, child) {
          // Afficher l'indicateur de chargement
          if (store.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Afficher l'erreur si elle existe
          if (store.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    store.error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      store.clearError();
                      store.loadProjects();
                    },
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          // État vide
          if (!store.hasProjects) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.folder_open, size: 64),
                  const SizedBox(height: 16),
                  const Text('Aucun projet'),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showCreateDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Créer un projet'),
                  ),
                ],
              ),
            );
          }

          // Liste des projets
          return Column(
            children: [
              // En-tête avec compteur
              Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                child: Row(
                  children: [
                    Text(
                      '${store.projectCount} projet${store.projectCount > 1 ? "s" : ""}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              // Liste
              Expanded(
                child: ListView.builder(
                  itemCount: store.projectCount,
                  itemBuilder: (context, index) {
                    final project = store.projects[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(project.title[0].toUpperCase()),
                        ),
                        title: Text(project.title),
                        subtitle: project.description != null
                            ? Text(
                                project.description!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              )
                            : null,
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            switch (value) {
                              case 'edit':
                                _showEditDialog(context, project);
                                break;
                              case 'delete':
                                _confirmDelete(context, project);
                                break;
                              case 'refresh':
                                store.refreshProject(project.id!);
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit),
                                  SizedBox(width: 8),
                                  Text('Modifier'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'refresh',
                              child: Row(
                                children: [
                                  Icon(Icons.refresh),
                                  SizedBox(width: 8),
                                  Text('Rafraîchir'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text(
                                    'Supprimer',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
