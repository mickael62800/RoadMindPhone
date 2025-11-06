import 'package:roadmindphone/services/export_service/mark_sessions_exported.dart';
import 'package:flutter/material.dart';
import 'package:roadmindphone/features/project/domain/entities/project_entity.dart';
import 'package:roadmindphone/session.dart';
import 'package:http/http.dart' as http;

import 'package:roadmindphone/services/export_service/check_project_exists_by_name.dart';
import 'package:roadmindphone/services/export_service/create_project.dart';
import 'package:roadmindphone/services/export_service/create_sessions.dart';
import 'package:roadmindphone/core/api_base_url.dart';

class ExportDataPage extends StatefulWidget {
  final ProjectEntity project;
  final List<Session> sessions;
  final http.Client? httpClient;

  const ExportDataPage({
    super.key,
    required this.project,
    this.sessions = const [],
    this.httpClient,
  });

  @override
  State<ExportDataPage> createState() => _ExportDataPageState();
}

class _ExportDataPageState extends State<ExportDataPage> {
  Future<void> _checkProjectExistsByName() async {
    if (_baseUrl == null) return;
    final exists = await checkProjectExistsByName(
      client: _client,
      baseUrl: _baseUrl!,
      projectName: widget.project.title,
    );
    setState(() {
      _projectExists = exists;
    });
  }

  bool? _projectExists;
  late final http.Client _client;
  String? _baseUrl;

  @override
  void initState() {
    super.initState();
    _client = widget.httpClient ?? http.Client();
    _initBaseUrlAndCheck();
  }

  Future<void> _initBaseUrlAndCheck() async {
    final baseUrl = await getApiBaseUrlFromSettings();
    setState(() {
      _baseUrl = baseUrl;
    });
    await _checkProjectExistsByName();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Exportation du projet'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
        elevation: 2,
      ),
      body: Center(
        child: _projectExists == null
            ? const CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(28.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _projectExists!
                                ? Colors.green[50]
                                : Colors.blue[50],
                          ),
                          padding: const EdgeInsets.all(18),
                          child: Icon(
                            Icons.cloud_upload,
                            size: 70,
                            color: _projectExists! ? Colors.green : Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          widget.project.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _projectExists!
                              ? 'Le projet existe déjà sur le serveur.'
                              : 'Ce projet n\'existe pas encore sur le serveur.',
                          style: TextStyle(
                            fontSize: 16,
                            color: _projectExists!
                                ? Colors.green[700]
                                : Colors.blue[700],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 18),
                        Text(
                          _projectExists!
                              ? 'Vous pouvez ajouter de nouvelles sessions à ce projet.'
                              : 'Appuyez sur le bouton ci-dessous pour créer le dossier distant.',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: Icon(
                              _projectExists!
                                  ? Icons.add
                                  : Icons.create_new_folder,
                            ),
                            onPressed: () async {
                              if (_projectExists!) {
                                await _addSessions();
                              } else {
                                await _createProject();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _projectExists!
                                  ? Colors.green
                                  : Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              textStyle: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            label: Text(
                              _projectExists!
                                  ? 'Ajouter des sessions'
                                  : 'Créer le dossier',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Future<void> _createProject() async {
    if (_baseUrl == null) return;
    try {
      await createProject(
        client: _client,
        baseUrl: _baseUrl!,
        project: widget.project,
        sessions: widget.sessions,
      );
      // Marquer les sessions comme exportées dans la base locale
      await markSessionsExported(widget.sessions);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Projet créé avec succès !')),
      );
      setState(() {
        _projectExists = true;
      });
    } catch (e) {
      final errorMsg = _extractErrorMessage(e);
      debugPrint('Erreur création projet: $errorMsg');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la création du projet : $errorMsg'),
        ),
      );
    }
  }

  Future<void> _addSessions() async {
    if (_baseUrl == null) return;
    try {
      await createSessions(
        client: _client,
        baseUrl: _baseUrl!,
        projectName: widget.project.title,
        sessions: widget.sessions,
      );
      // Marquer les sessions comme exportées dans la base locale
      await markSessionsExported(widget.sessions);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sessions ajoutées avec succès !')),
      );
    } catch (e) {
      final errorMsg = _extractErrorMessage(e);
      debugPrint('Erreur ajout sessions: $errorMsg');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'ajout des sessions : $errorMsg'),
        ),
      );
    }
  }

  String _extractErrorMessage(Object e) {
    final str = e.toString();
    final regex = RegExp(r'Exception: ([^\n]+)');
    final match = regex.firstMatch(str);
    if (match != null && match.groupCount > 0) {
      return match.group(1)!;
    }
    // Fallback: return first line or the string itself
    return str.split('\n').first;
  }
}
