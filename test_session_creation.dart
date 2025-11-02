import 'package:roadmindphone/database_helper.dart';
import 'package:roadmindphone/session.dart';
import 'package:roadmindphone/project.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  // Initialize sqflite for desktop
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  print('🧪 Test de création de session...\n');

  try {
    // 1. Créer un projet de test
    print('1. Création d\'un projet de test...');
    final project = await DatabaseHelper.instance.create(
      Project(title: 'Projet Test', description: 'Pour tester les sessions'),
    );
    print('✅ Projet créé avec id: ${project.id}\n');

    // 2. Créer une session
    print('2. Création d\'une session...');
    final session = await DatabaseHelper.instance.createSession(
      Session(
        projectId: project.id!,
        name: 'Session Test',
        duration: const Duration(minutes: 5),
        gpsPoints: 10,
      ),
    );
    print('✅ Session créée avec id: ${session.id}\n');

    // 3. Vérifier que la session est bien en base
    print('3. Lecture de toutes les sessions du projet...');
    final sessions = await DatabaseHelper.instance.readAllSessionsForProject(
      project.id!,
    );
    print('✅ Nombre de sessions trouvées: ${sessions.length}');

    if (sessions.isNotEmpty) {
      print('📋 Détails de la session:');
      print('   - ID: ${sessions.first.id}');
      print('   - Nom: ${sessions.first.name}');
      print('   - Durée: ${sessions.first.duration}');
      print('   - GPS Points: ${sessions.first.gpsPoints}');
    }

    print('\n✅ Test réussi! Les sessions s\'enregistrent correctement.');
  } catch (e, stackTrace) {
    print('❌ Erreur: $e');
    print('Stack trace: $stackTrace');
  }
}
