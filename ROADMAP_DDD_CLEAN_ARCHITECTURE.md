# 🚀 Feuille de Route : Migration vers DDD & Clean Architecture

**Projet** : RoadMindPhone  
**Date de début** : 2 novembre 2025  
**Principe fondamental** : ✅ **Chaque modification = Full Test (240 unit + 10 E2E)**

---

## 📊 État Actuel

### ✅ Points Forts

- **Tests** : 240 tests unitaires + 10 E2E (90.1% coverage)
- **Stores** : ProjectStore et SessionStore déjà implémentés
- **Modèles** : Project, Session, SessionGpsPoint bien définis
- **Code Quality** : `flutter analyze` sans erreurs

### 🔄 Architecture Actuelle

```
lib/
├── main.dart                    # Entry point + Model Project
├── database_helper.dart         # Direct DB access
├── session.dart                 # Model Session
├── session_gps_point.dart       # Model GPS
├── stores/
│   ├── project_store.dart       # State management
│   └── session_store.dart       # State management
├── *_page.dart                  # UI + Logic mélangés
└── src/
    └── ui/                      # Atomic Design (partiel)
```

### 🎯 Architecture Cible (Clean Architecture + DDD)

```
lib/
├── core/                        # Couche transversale
│   ├── error/                   # Gestion erreurs
│   ├── usecases/                # Cas d'usage de base
│   └── utils/                   # Utilitaires
├── features/                    # Bounded Contexts (DDD)
│   ├── project/
│   │   ├── domain/              # Logique métier pure
│   │   │   ├── entities/        # Entités métier
│   │   │   ├── repositories/    # Interfaces repositories
│   │   │   └── usecases/        # Cas d'usage métier
│   │   ├── data/                # Implémentation données
│   │   │   ├── datasources/     # Sources de données
│   │   │   ├── models/          # DTOs/Models
│   │   │   └── repositories/    # Implémentation repos
│   │   └── presentation/        # UI
│   │       ├── bloc/            # State management
│   │       ├── pages/           # Pages
│   │       └── widgets/         # Composants UI
│   └── session/                 # Même structure
└── shared/                      # Code partagé
```

---

## 📋 Phase 1 : Fondations (Semaine 1)

### 🎯 Objectif

Créer la structure de base sans casser le code existant

### Étape 1.1 : Structure Core

**Durée** : 2h  
**Validation** : ✅ 240 + 10 tests passent

#### Actions

1. Créer `lib/core/error/failures.dart`

   ```dart
   abstract class Failure {
     final String message;
     const Failure(this.message);
   }

   class DatabaseFailure extends Failure {
     const DatabaseFailure(super.message);
   }

   class NetworkFailure extends Failure {
     const NetworkFailure(super.message);
   }
   ```

2. Créer `lib/core/usecases/usecase.dart`

   ```dart
   import 'package:dartz/dartz.dart';
   import '../error/failures.dart';

   abstract class UseCase<Type, Params> {
     Future<Either<Failure, Type>> call(Params params);
   }
   ```

3. Créer `lib/core/utils/typedef.dart`

   ```dart
   import 'package:dartz/dartz.dart';
   import '../error/failures.dart';

   typedef ResultFuture<T> = Future<Either<Failure, T>>;
   typedef ResultVoid = Future<Either<Failure, void>>;
   ```

**Tests à créer** :

- `test/core/error/failures_test.dart`
- `test/core/usecases/usecase_test.dart`

**Commande de validation** :

```bash
flutter test
flutter test integration_test/ -d linux
```

---

### Étape 1.2 : Structure Features

**Durée** : 1h  
**Validation** : ✅ 240 + 10 tests passent

#### Actions

1. Créer la structure des dossiers :

```bash
mkdir -p lib/features/project/{domain,data,presentation}/{entities,repositories,usecases,datasources,models,bloc,pages,widgets}
mkdir -p lib/features/session/{domain,data,presentation}/{entities,repositories,usecases,datasources,models,bloc,pages,widgets}
```

2. Créer les fichiers `.gitkeep` pour garder les dossiers

**Commande de validation** :

```bash
flutter test
flutter analyze
```

---

### Étape 1.3 : Ajouter Dépendances

**Durée** : 30min  
**Validation** : ✅ 240 + 10 tests passent

#### Actions

Mettre à jour `pubspec.yaml` :

```yaml
dependencies:
  # Existing
  flutter:
    sdk: flutter
  provider: ^6.1.1

  # New for Clean Architecture
  dartz: ^0.10.1 # Either/Option pour gestion erreurs
  equatable: ^2.0.5 # Equality pour entities
  get_it: ^7.6.4 # Dependency Injection

dev_dependencies:
  mockito: ^5.4.4
  build_runner: ^2.4.6
```

**Commandes** :

```bash
flutter pub get
flutter test
```

---

## 📋 Phase 2 : Migration Feature Project (Semaine 2)

### 🎯 Objectif

Migrer la feature Project vers Clean Architecture

### Étape 2.1 : Domain Layer - Entities

**Durée** : 3h  
**Validation** : ✅ 240 + 10 tests passent

#### Actions

1. Créer `lib/features/project/domain/entities/project_entity.dart`

   ```dart
   import 'package:equatable/equatable.dart';

   class ProjectEntity extends Equatable {
     final int? id;
     final String title;
     final String? description;
     final DateTime createdAt;
     final DateTime? updatedAt;

     const ProjectEntity({
       this.id,
       required this.title,
       this.description,
       required this.createdAt,
       this.updatedAt,
     });

     @override
     List<Object?> get props => [id, title, description, createdAt, updatedAt];
   }
   ```

2. Garder l'ancien `Project` class pour compatibilité
3. Créer un adaptateur temporaire

**Tests** :

- `test/features/project/domain/entities/project_entity_test.dart`
  - Test equality
  - Test props
  - Test copyWith

**Commande de validation** :

```bash
flutter test
flutter test test/features/project/domain/entities/
```

---

### Étape 2.2 : Domain Layer - Repository Interface

**Durée** : 2h  
**Validation** : ✅ 240 + 10 tests passent

#### Actions

Créer `lib/features/project/domain/repositories/project_repository.dart`

```dart
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/project_entity.dart';

abstract class ProjectRepository {
  Future<Either<Failure, List<ProjectEntity>>> getProjects();
  Future<Either<Failure, ProjectEntity>> getProjectById(int id);
  Future<Either<Failure, ProjectEntity>> createProject(ProjectEntity project);
  Future<Either<Failure, void>> updateProject(ProjectEntity project);
  Future<Either<Failure, void>> deleteProject(int id);
}
```

**Pas de tests nécessaires** (interface pure)

---

### Étape 2.3 : Domain Layer - Use Cases

**Durée** : 4h  
**Validation** : ✅ 240 + 10 tests passent

#### Actions

Créer 5 use cases :

1. `lib/features/project/domain/usecases/get_projects.dart`
2. `lib/features/project/domain/usecases/get_project_by_id.dart`
3. `lib/features/project/domain/usecases/create_project.dart`
4. `lib/features/project/domain/usecases/update_project.dart`
5. `lib/features/project/domain/usecases/delete_project.dart`

**Exemple** :

```dart
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/project_entity.dart';
import '../repositories/project_repository.dart';

class GetProjects implements UseCase<List<ProjectEntity>, NoParams> {
  final ProjectRepository repository;

  GetProjects(this.repository);

  @override
  Future<Either<Failure, List<ProjectEntity>>> call(NoParams params) {
    return repository.getProjects();
  }
}

class NoParams {}
```

**Tests** :

- `test/features/project/domain/usecases/get_projects_test.dart`
- etc. (5 fichiers de test)

Chaque test doit :

- Mocker le repository
- Vérifier que le usecase appelle le repository
- Vérifier le retour Success/Failure

**Commande de validation** :

```bash
flutter test test/features/project/domain/usecases/
flutter test  # Tous les tests
```

---

### Étape 2.4 : Data Layer - Models

**Durée** : 3h  
**Validation** : ✅ 240 + 10 tests passent

#### Actions

Créer `lib/features/project/data/models/project_model.dart`

```dart
import '../../domain/entities/project_entity.dart';

class ProjectModel extends ProjectEntity {
  const ProjectModel({
    super.id,
    required super.title,
    super.description,
    required super.createdAt,
    super.updatedAt,
  });

  // From JSON
  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'] as int?,
      title: json['title'] as String,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
        ? DateTime.parse(json['updatedAt'] as String)
        : null,
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // From Entity
  factory ProjectModel.fromEntity(ProjectEntity entity) {
    return ProjectModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
```

**Tests** :

- `test/features/project/data/models/project_model_test.dart`
  - Test fromJson
  - Test toJson
  - Test fromEntity
  - Test is subclass of ProjectEntity

**Commande de validation** :

```bash
flutter test test/features/project/data/models/
flutter test
```

---

### Étape 2.5 : Data Layer - DataSource

**Durée** : 4h  
**Validation** : ✅ 240 + 10 tests passent

#### Actions

1. Créer `lib/features/project/data/datasources/project_local_data_source.dart`

```dart
import '../models/project_model.dart';

abstract class ProjectLocalDataSource {
  Future<List<ProjectModel>> getProjects();
  Future<ProjectModel> getProjectById(int id);
  Future<ProjectModel> createProject(ProjectModel project);
  Future<void> updateProject(ProjectModel project);
  Future<void> deleteProject(int id);
}

class ProjectLocalDataSourceImpl implements ProjectLocalDataSource {
  final DatabaseHelper databaseHelper;

  ProjectLocalDataSourceImpl(this.databaseHelper);

  @override
  Future<List<ProjectModel>> getProjects() async {
    try {
      final projects = await databaseHelper.readAllProjects();
      return projects.map((p) => ProjectModel.fromEntity(p)).toList();
    } catch (e) {
      throw DatabaseException(e.toString());
    }
  }

  // ... autres méthodes
}
```

2. Créer les exceptions personnalisées

**Tests** :

- `test/features/project/data/datasources/project_local_data_source_test.dart`
  - Mock DatabaseHelper
  - Test tous les cas Success
  - Test tous les cas Exception

**Commande de validation** :

```bash
flutter test test/features/project/data/datasources/
flutter test
```

---

### Étape 2.6 : Data Layer - Repository Implementation

**Durée** : 4h  
**Validation** : ✅ 240 + 10 tests passent

#### Actions

Créer `lib/features/project/data/repositories/project_repository_impl.dart`

```dart
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/project_entity.dart';
import '../../domain/repositories/project_repository.dart';
import '../datasources/project_local_data_source.dart';
import '../models/project_model.dart';

class ProjectRepositoryImpl implements ProjectRepository {
  final ProjectLocalDataSource localDataSource;

  ProjectRepositoryImpl(this.localDataSource);

  @override
  Future<Either<Failure, List<ProjectEntity>>> getProjects() async {
    try {
      final projects = await localDataSource.getProjects();
      return Right(projects);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  // ... autres méthodes
}
```

**Tests** :

- `test/features/project/data/repositories/project_repository_impl_test.dart`
  - Mock DataSource
  - Test tous les cas Success → Right
  - Test tous les cas Exception → Left(Failure)

**Commande de validation** :

```bash
flutter test test/features/project/data/repositories/
flutter test
```

---

### Étape 2.7 : Dependency Injection

**Durée** : 2h  
**Validation** : ✅ 240 + 10 tests passent

#### Actions

Créer `lib/injection_container.dart`

```dart
import 'package:get_it/get_it.dart';
import 'features/project/data/datasources/project_local_data_source.dart';
import 'features/project/data/repositories/project_repository_impl.dart';
import 'features/project/domain/repositories/project_repository.dart';
import 'features/project/domain/usecases/get_projects.dart';
import 'features/project/domain/usecases/create_project.dart';
// ... autres imports

final sl = GetIt.instance;

Future<void> init() async {
  // Features - Project

  // UseCases
  sl.registerLazySingleton(() => GetProjects(sl()));
  sl.registerLazySingleton(() => CreateProject(sl()));
  sl.registerLazySingleton(() => UpdateProject(sl()));
  sl.registerLazySingleton(() => DeleteProject(sl()));
  sl.registerLazySingleton(() => GetProjectById(sl()));

  // Repository
  sl.registerLazySingleton<ProjectRepository>(
    () => ProjectRepositoryImpl(sl()),
  );

  // DataSources
  sl.registerLazySingleton<ProjectLocalDataSource>(
    () => ProjectLocalDataSourceImpl(sl()),
  );

  // Core
  sl.registerLazySingleton(() => DatabaseHelper.instance);
}
```

Mettre à jour `main.dart` :

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await init(); // Initialize DI
  runApp(MyApp());
}
```

**Tests** :

- Aucun test nouveau, mais vérifier que tout fonctionne

**Commande de validation** :

```bash
flutter test
flutter test integration_test/ -d linux
```

---

### Étape 2.8 : Migration ProjectStore vers BLoC

**Durée** : 6h  
**Validation** : ✅ 240 + 10 tests passent

#### Actions

1. Ajouter `flutter_bloc` au pubspec.yaml
2. Créer `lib/features/project/presentation/bloc/project_bloc.dart`
3. Créer events, states
4. Remplacer progressivement ProjectStore par ProjectBloc
5. **Garder ProjectStore temporairement** pour compatibilité

**Tests** :

- `test/features/project/presentation/bloc/project_bloc_test.dart`
  - Mock tous les use cases
  - Test tous les events → states
  - Vérifier les appels aux use cases

**Commande de validation** :

```bash
flutter test test/features/project/presentation/bloc/
flutter test
flutter test integration_test/ -d linux
```

---

### Étape 2.9 : Migration UI vers Clean Presentation

**Durée** : 8h  
**Validation** : ✅ 240 + 10 tests passent

#### Actions

1. Déplacer les widgets vers `lib/features/project/presentation/widgets/`
2. Créer les pages dans `lib/features/project/presentation/pages/`
3. Mettre à jour les imports
4. Remplacer `Provider<ProjectStore>` par `BlocProvider<ProjectBloc>`
5. **Migration progressive** : garder les anciens fichiers jusqu'à ce que tous les tests passent

**Tests** :

- Adapter les tests de widgets existants
- Vérifier que tous les 240 + 10 tests passent

**Commande de validation** :

```bash
flutter test
flutter test integration_test/ -d linux
```

---

### Étape 2.10 : Nettoyage Project

**Durée** : 2h  
**Validation** : ✅ 240 + 10 tests passent

#### Actions

1. Supprimer `lib/stores/project_store.dart`
2. Supprimer les anciens fichiers de `lib/` (project_index_page.dart, etc.)
3. Mettre à jour tous les imports
4. Nettoyer les tests obsolètes

**Commande de validation** :

```bash
flutter analyze
flutter test
flutter test integration_test/ -d linux
```

---

## 📋 Phase 3 : Migration Feature Session (Semaine 3)

### 🎯 Objectif

Répéter le processus pour la feature Session

### Étapes (identiques à Phase 2)

1. ✅ Domain Layer - Entities (SessionEntity, SessionGpsPointEntity)
2. ✅ Domain Layer - Repository Interface
3. ✅ Domain Layer - Use Cases (7 use cases)
4. ✅ Data Layer - Models
5. ✅ Data Layer - DataSource
6. ✅ Data Layer - Repository Implementation
7. ✅ Dependency Injection (ajout à injection_container.dart)
8. ✅ Migration SessionStore vers BLoC
9. ✅ Migration UI
10. ✅ Nettoyage

**Validation à chaque étape** : ✅ 240 + 10 tests passent

---

## 📋 Phase 4 : Features Secondaires (Semaine 4)

### 🎯 Objectif

Migrer les features restantes

### Étape 4.1 : Feature Settings

**Durée** : 4h

1. Créer `lib/features/settings/`
2. Domain → Data → Presentation
3. Tests complets

### Étape 4.2 : Feature Export

**Durée** : 4h

1. Créer `lib/features/export/`
2. Domain → Data → Presentation
3. Tests complets

**Validation** : ✅ 240 + 10 tests passent

---

## 📋 Phase 5 : Optimisations & Documentation (Semaine 5)

### Étape 5.1 : Refactoring & Optimisation

**Durée** : 8h

1. Identifier le code dupliqué
2. Créer des mixins/extensions partagés
3. Optimiser les performances
4. Améliorer la gestion d'erreur

**Validation** : ✅ 240 + 10 tests passent

---

### Étape 5.2 : Documentation

**Durée** : 4h

1. Documenter l'architecture dans `ARCHITECTURE.md`
2. Créer des diagrammes (PlantUML)
3. Mettre à jour le README
4. Documenter les bounded contexts DDD

---

### Étape 5.3 : Tests Supplémentaires

**Durée** : 6h

1. Augmenter la couverture à 95%+
2. Ajouter des tests d'intégration pour les repositories
3. Ajouter des tests E2E supplémentaires

**Objectif** : 300+ tests, 95%+ coverage

---

## 📊 Métriques de Succès

### Coverage Cible

- **Domain Layer** : 100% (logique métier pure)
- **Data Layer** : 95%+
- **Presentation Layer** : 90%+
- **Global** : 95%+

### Performance

- Build time : < 30s
- Test time : < 30s (unit), < 2min (integration)
- App startup : < 2s

### Quality Gates

```bash
# À chaque commit
flutter analyze                           # 0 issues
flutter test                              # All pass
flutter test integration_test/ -d linux   # All pass
flutter test --coverage                   # > 95%
```

---

## 🎯 Bounded Contexts DDD

### Context 1 : Project Management

**Ubiquitous Language** :

- Project : Un conteneur de sessions
- Archive : Marquer un projet comme archivé
- Restore : Restaurer un projet archivé

### Context 2 : Session Recording

**Ubiquitous Language** :

- Session : Une session d'enregistrement GPS + Vidéo
- Recording : État d'enregistrement actif
- Redo : Recommencer une session

### Context 3 : GPS Tracking

**Ubiquitous Language** :

- Track : Une séquence de points GPS
- Point : Une position GPS horodatée
- Accuracy : Précision du point GPS

---

## 🚨 Points d'Attention

### Risques Identifiés

1. **Breaking Changes** : Migration progressive obligatoire
2. **Test Maintenance** : 240 tests à adapter
3. **Learning Curve** : Équipe doit comprendre Clean Architecture
4. **Over-Engineering** : Ne pas sur-complexifier

### Mitigation

- ✅ Feature Flags pour migration progressive
- ✅ Adaptateurs temporaires entre ancien/nouveau code
- ✅ Documentation continue
- ✅ Code reviews strictes

---

## 📅 Timeline Résumé

| Phase                          | Durée     | Tests  | Objectif                   |
| ------------------------------ | --------- | ------ | -------------------------- |
| Phase 1 : Fondations           | 1 semaine | 240+10 | Structure de base          |
| Phase 2 : Feature Project      | 1 semaine | 240+10 | Migration complète Project |
| Phase 3 : Feature Session      | 1 semaine | 240+10 | Migration complète Session |
| Phase 4 : Features Secondaires | 1 semaine | 240+10 | Settings, Export           |
| Phase 5 : Optimisation         | 1 semaine | 300+   | Polish & Documentation     |

**Total** : 5 semaines (~100h)

---

## ✅ Checklist de Validation

Après chaque phase :

- [ ] `flutter analyze` : 0 issues
- [ ] `flutter test` : All 240 tests pass
- [ ] `flutter test integration_test/` : All 10 E2E pass
- [ ] `flutter test --coverage` : Coverage maintenue
- [ ] Code review effectué
- [ ] Documentation mise à jour
- [ ] Commit avec message descriptif
- [ ] Push vers repository

---

## 🎓 Ressources & Formation

### Lectures Recommandées

1. "Clean Architecture" - Robert C. Martin
2. "Domain-Driven Design" - Eric Evans
3. "Flutter Clean Architecture" - Reso Coder (série YouTube)

### Patterns à Maîtriser

- Repository Pattern
- Use Case Pattern
- Dependency Injection
- BLoC Pattern
- Either/Option (functional programming)

---

## 🔄 Versioning

### Stratégie de Branches

```
master (stable)
  ↓
develop (integration)
  ↓
feature/clean-arch-phase-1
feature/clean-arch-phase-2
...
```

### Releases

- **v1.0.0** : État actuel (avant migration)
- **v2.0.0-alpha** : Phase 1 complétée
- **v2.0.0-beta** : Phases 2-3 complétées
- **v2.0.0** : Migration complète

---

## 📞 Support

En cas de blocage :

1. Consulter la documentation des packages (dartz, get_it, flutter_bloc)
2. Référencer cette roadmap
3. Faire un point d'équipe

---

**Créé le** : 2 novembre 2025  
**Auteur** : GitHub Copilot  
**Version** : 1.0  
**Status** : 📋 Prêt à démarrer

---

## 🚀 Commande de Démarrage

```bash
# Créer une branche pour la migration
git checkout -b feature/clean-arch-phase-1

# Commencer par Phase 1, Étape 1.1
mkdir -p lib/core/{error,usecases,utils}
```

**Rappel** : Après CHAQUE modification, lancer :

```bash
flutter test && flutter test integration_test/ -d linux
```

✅ **GO !**
