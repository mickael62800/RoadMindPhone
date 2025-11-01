# Project Store

## Description

Le `ProjectStore` est un gestionnaire d'état pour les projets de l'application RoadMindPhone. Il utilise le pattern `ChangeNotifier` de Flutter pour notifier les widgets des changements d'état.

## Architecture

```
lib/stores/
├── project_store.dart    # Implémentation du store
└── README.md            # Documentation

test/stores/
└── project_store_test.dart  # Tests unitaires
```

## Utilisation

### Initialisation

```dart
import 'package:provider/provider.dart';
import 'package:roadmindphone/stores/project_store.dart';

// Dans main.dart ou au niveau de l'app
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ProjectStore(),
      child: MyApp(),
    ),
  );
}
```

### Accès au store dans un widget

```dart
import 'package:provider/provider.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final projectStore = Provider.of<ProjectStore>(context);

    // Ou avec Consumer pour un rebuild ciblé
    return Consumer<ProjectStore>(
      builder: (context, store, child) {
        if (store.isLoading) {
          return CircularProgressIndicator();
        }

        if (store.error != null) {
          return Text('Erreur: ${store.error}');
        }

        return ListView.builder(
          itemCount: store.projectCount,
          itemBuilder: (context, index) {
            final project = store.projects[index];
            return ListTile(title: Text(project.title));
          },
        );
      },
    );
  }
}
```

## API

### Propriétés (Getters)

- `projects`: Liste immutable des projets
- `isLoading`: Indique si une opération est en cours
- `error`: Message d'erreur si une opération a échoué
- `hasProjects`: Retourne true si des projets existent
- `projectCount`: Nombre de projets

### Méthodes

#### `loadProjects()`

Charge tous les projets depuis la base de données.

```dart
await projectStore.loadProjects();
```

#### `createProject(String title, {String? description})`

Crée un nouveau projet.

```dart
final project = await projectStore.createProject(
  'Mon Projet',
  description: 'Description optionnelle',
);
```

#### `updateProject(Project project)`

Met à jour un projet existant.

```dart
final updatedProject = project.copyWith(title: 'Nouveau titre');
await projectStore.updateProject(updatedProject);
```

#### `deleteProject(int projectId)`

Supprime un projet.

```dart
await projectStore.deleteProject(1);
```

#### `getProjectById(int id)`

Récupère un projet par son ID (retourne null si non trouvé).

```dart
final project = projectStore.getProjectById(1);
if (project != null) {
  print(project.title);
}
```

#### `refreshProject(int projectId)`

Rafraîchit un projet spécifique depuis la base de données.

```dart
await projectStore.refreshProject(1);
```

#### `clearError()`

Efface le message d'erreur actuel.

```dart
projectStore.clearError();
```

## Gestion des erreurs

Le store capture automatiquement les erreurs et les expose via la propriété `error`. Les méthodes lèvent également l'exception pour permettre une gestion locale si nécessaire.

```dart
try {
  await projectStore.createProject('Test');
} catch (e) {
  // Gestion locale de l'erreur
  print('Erreur: $e');
}

// L'erreur est aussi disponible dans store.error
if (projectStore.error != null) {
  showDialog(...);
  projectStore.clearError();
}
```

## Notifications

Le store notifie automatiquement tous les listeners (widgets) lors des changements suivants :

- Début/fin de chargement
- Ajout d'un projet
- Mise à jour d'un projet
- Suppression d'un projet
- Erreur
- Rafraîchissement d'un projet

## Tests

Les tests unitaires couvrent tous les cas d'usage :

- État initial
- Chargement des projets
- Création, mise à jour, suppression
- Gestion des erreurs
- Notifications aux listeners

```bash
# Lancer les tests
flutter test test/stores/project_store_test.dart

# Avec coverage
flutter test --coverage test/stores/project_store_test.dart
```

## Dépendances

- `flutter/foundation.dart` : Pour ChangeNotifier
- `database_helper.dart` : Pour les opérations de base de données
- `main.dart` : Pour la classe Project

## TODO

- [ ] Ajouter support pour le tri des projets
- [ ] Ajouter support pour la recherche
- [ ] Ajouter support pour la pagination
- [ ] Implémenter le cache local
- [ ] Ajouter des métriques (temps de chargement, etc.)

## Contributeurs

- Créé pour RoadMindPhone
- Date: 1 novembre 2025
