# Features - Clean Architecture Structure

Cette structure implémente les principes de Clean Architecture et Domain-Driven Design (DDD).

## 📁 Structure des Features

Chaque feature (bounded context) est organisée en 3 couches principales :

```
features/
├── project/                    # Feature Project Management
│   ├── domain/                 # 🎯 Couche Domaine (Business Logic)
│   │   ├── entities/          # Entités métier (pure Dart, pas de dépendances)
│   │   ├── repositories/      # Interfaces des repositories (contrats)
│   │   └── usecases/          # Cas d'usage métier (business operations)
│   ├── data/                   # 💾 Couche Données (Implémentation)
│   │   ├── datasources/       # Sources de données (local, remote, cache)
│   │   ├── models/            # DTOs/Models pour sérialisation
│   │   └── repositories/      # Implémentations des repositories
│   └── presentation/           # 🎨 Couche Présentation (UI)
│       ├── bloc/              # State management (BLoC pattern)
│       ├── pages/             # Pages/Screens
│       └── widgets/           # Widgets réutilisables
│
└── session/                    # Feature Session Recording
    ├── domain/
    ├── data/
    └── presentation/
```

## 🎯 Principes de Clean Architecture

### 1. **Domain Layer** (Couche Domaine)

- **Pas de dépendances** externes (Flutter, packages, etc.)
- **Pure Dart** : logique métier uniquement
- **Testable** à 100% sans mocks
- **Indépendant** de la UI et de la base de données

#### Entities (Entités)

- Objets métier avec règles de validation
- Utilisent `equatable` pour l'égalité
- Immutables (final, const, copyWith)

```dart
class ProjectEntity extends Equatable {
  final int? id;
  final String title;
  final String? description;
  final DateTime createdAt;

  const ProjectEntity({...});

  @override
  List<Object?> get props => [id, title, description, createdAt];
}
```

#### Repositories (Interfaces)

- **Contrats** définissant les opérations
- Retournent `Either<Failure, T>` (dartz)
- Pas d'implémentation, que des signatures

```dart
abstract class ProjectRepository {
  Future<Either<Failure, List<ProjectEntity>>> getProjects();
  Future<Either<Failure, ProjectEntity>> createProject(ProjectEntity project);
}
```

#### UseCases (Cas d'usage)

- **Une action métier** = un use case
- Orchestrent les repositories
- Appliquent les règles métier

```dart
class GetProjects implements UseCase<List<ProjectEntity>, NoParams> {
  final ProjectRepository repository;

  GetProjects(this.repository);

  @override
  Future<Either<Failure, List<ProjectEntity>>> call(NoParams params) {
    return repository.getProjects();
  }
}
```

---

### 2. **Data Layer** (Couche Données)

#### DataSources (Sources de données)

- Accès aux données (DB, API, Cache)
- Lancent des **Exceptions** (pas des Failures)
- Implémentations concrètes

```dart
class ProjectLocalDataSourceImpl implements ProjectLocalDataSource {
  final DatabaseHelper db;

  @override
  Future<List<ProjectModel>> getProjects() async {
    try {
      final projects = await db.readAllProjects();
      return projects.map((p) => ProjectModel.fromEntity(p)).toList();
    } catch (e) {
      throw DatabaseException(e.toString());
    }
  }
}
```

#### Models (DTOs)

- **Extension des entities** pour sérialisation
- Méthodes `fromJson`, `toJson`, `fromEntity`
- Pas de logique métier

```dart
class ProjectModel extends ProjectEntity {
  const ProjectModel({...}) : super(...);

  factory ProjectModel.fromJson(Map<String, dynamic> json) {...}
  Map<String, dynamic> toJson() {...}
  factory ProjectModel.fromEntity(ProjectEntity entity) {...}
}
```

#### Repositories Implementation

- Implémentent les interfaces du domain
- Convertissent **Exceptions → Failures**
- Gèrent les erreurs avec `Either`

```dart
class ProjectRepositoryImpl implements ProjectRepository {
  final ProjectLocalDataSource localDataSource;

  @override
  Future<Either<Failure, List<ProjectEntity>>> getProjects() async {
    try {
      final projects = await localDataSource.getProjects();
      return Right(projects);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    }
  }
}
```

---

### 3. **Presentation Layer** (Couche Présentation)

#### BLoC (State Management)

- Pattern BLoC (Business Logic Component)
- Events → BLoC → States
- Séparation UI / Logic

```dart
// Events
abstract class ProjectEvent extends Equatable {}
class LoadProjects extends ProjectEvent {}

// States
abstract class ProjectState extends Equatable {}
class ProjectsLoaded extends ProjectState {
  final List<ProjectEntity> projects;
}

// BLoC
class ProjectBloc extends Bloc<ProjectEvent, ProjectState> {
  final GetProjects getProjects;

  ProjectBloc({required this.getProjects}) : super(ProjectInitial()) {
    on<LoadProjects>(_onLoadProjects);
  }

  Future<void> _onLoadProjects(LoadProjects event, Emitter<ProjectState> emit) async {
    emit(ProjectsLoading());
    final result = await getProjects(NoParams());
    result.fold(
      (failure) => emit(ProjectsError(failure.message)),
      (projects) => emit(ProjectsLoaded(projects)),
    );
  }
}
```

#### Pages

- Screens principales de l'application
- Utilisent BlocProvider, BlocBuilder
- Délèguent la logique au BLoC

#### Widgets

- Composants réutilisables
- Stateless autant que possible
- Atomic Design pattern

---

## 🔄 Flux de Données

```
User Action (UI)
    ↓
Event (Presentation)
    ↓
BLoC (Presentation)
    ↓
UseCase (Domain)
    ↓
Repository Interface (Domain)
    ↓
Repository Implementation (Data)
    ↓
DataSource (Data)
    ↓
Database / API
    ↓
Model (Data)
    ↓
Entity (Domain)
    ↓
State (Presentation)
    ↓
UI Update
```

---

## 🧪 Tests

Chaque couche a sa propre suite de tests :

```
test/features/
├── project/
│   ├── domain/
│   │   ├── entities/          # Test entities (equality, props)
│   │   └── usecases/          # Test use cases (mock repositories)
│   ├── data/
│   │   ├── datasources/       # Test data sources (mock database)
│   │   ├── models/            # Test serialization (fromJson, toJson)
│   │   └── repositories/      # Test repository impl (mock datasources)
│   └── presentation/
│       └── bloc/              # Test BLoC (mock use cases)
```

### Stratégie de Tests

1. **Domain Layer** : Tests unitaires purs (pas de mocks Flutter)
2. **Data Layer** : Tests avec mocks des sources de données
3. **Presentation Layer** : Tests de widgets + BLoC

---

## 📚 Bounded Contexts (DDD)

### Context : Project Management

**Ubiquitous Language** :

- Project : Conteneur de sessions d'enregistrement
- Archive : Marquer un projet comme inactif
- Restore : Réactiver un projet archivé

### Context : Session Recording

**Ubiquitous Language** :

- Session : Enregistrement GPS + Vidéo
- Recording : État d'enregistrement actif
- Track : Séquence de points GPS
- Redo : Recommencer une session (effacer données)

---

## 🚀 Migration Progressive

La migration se fait **feature par feature** :

1. ✅ Phase 1 : Structure core (failures, usecases, typedef)
2. 🔄 Phase 2 : Feature Project
   - Domain → Data → Presentation
3. ⏳ Phase 3 : Feature Session
4. ⏳ Phase 4 : Features secondaires (Settings, Export)

---

## 📖 Références

- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html) - Uncle Bob
- [Domain-Driven Design](https://martinfowler.com/bliki/DomainDrivenDesign.html) - Eric Evans
- [Flutter BLoC Pattern](https://bloclibrary.dev/) - Felix Angelov
- [Reso Coder - Flutter Clean Architecture](https://resocoder.com/flutter-clean-architecture-tdd/)

---

**Créé le** : 2 novembre 2025  
**Status** : 📁 Structure prête pour implémentation  
**Prochaine étape** : Implémentation Domain Layer - Project
