import 'package:flutter/foundation.dart';
import '../database_helper.dart';
import '../main.dart';

/// Store pour gérer l'état des projets dans l'application
/// Utilise ChangeNotifier pour notifier les widgets des changements
class ProjectStore extends ChangeNotifier {
  final DatabaseHelper _databaseHelper;

  List<Project> _projects = [];
  bool _isLoading = false;
  String? _error;

  ProjectStore({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  // Getters
  List<Project> get projects => List.unmodifiable(_projects);
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasProjects => _projects.isNotEmpty;
  int get projectCount => _projects.length;

  /// Charge tous les projets depuis la base de données
  Future<void> loadProjects() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _projects = await _databaseHelper.readAllProjects();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Erreur lors du chargement des projets: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Crée un nouveau projet
  Future<Project> createProject(String title, {String? description}) async {
    try {
      final project = Project(title: title, description: description);

      final createdProject = await _databaseHelper.create(project);
      _projects.add(createdProject);
      notifyListeners();

      return createdProject;
    } catch (e) {
      _error = 'Erreur lors de la création du projet: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Met à jour un projet existant
  Future<void> updateProject(Project project) async {
    try {
      await _databaseHelper.update(project);

      final index = _projects.indexWhere((p) => p.id == project.id);
      if (index != -1) {
        _projects[index] = project;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Erreur lors de la mise à jour du projet: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Supprime un projet
  Future<void> deleteProject(int projectId) async {
    try {
      await _databaseHelper.delete(projectId);
      _projects.removeWhere((p) => p.id == projectId);
      notifyListeners();
    } catch (e) {
      _error = 'Erreur lors de la suppression du projet: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Récupère un projet par son ID
  Project? getProjectById(int id) {
    try {
      return _projects.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Rafraîchit un projet spécifique
  Future<void> refreshProject(int projectId) async {
    try {
      final updatedProject = await _databaseHelper.readProject(projectId);
      final index = _projects.indexWhere((p) => p.id == projectId);
      if (index != -1) {
        _projects[index] = updatedProject;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Erreur lors du rafraîchissement du projet: $e';
      notifyListeners();
    }
  }

  /// Efface l'erreur actuelle
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
