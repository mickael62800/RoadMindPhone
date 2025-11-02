import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:roadmindphone/core/di/injection_container.dart';
import 'package:roadmindphone/features/project/presentation/bloc/project_bloc.dart';
import 'package:roadmindphone/features/project/presentation/pages/pages.dart';
import 'package:roadmindphone/settings_page.dart';
import 'package:roadmindphone/stores/project_store.dart';
import 'package:roadmindphone/stores/session_store.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Configuration flag to choose between old and new architecture
///
/// Set to true to use Clean Architecture with BLoC
/// Set to false to use old Provider-based architecture
const bool USE_CLEAN_ARCHITECTURE = true;

/// Main entry point of the application
///
/// Supports both:
/// - Clean Architecture with BLoC (new)
/// - Provider-based architecture (old, for backward compatibility)
Future<void> main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize sqflite for desktop platforms
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Initialize dependencies based on architecture choice
  if (USE_CLEAN_ARCHITECTURE) {
    await initializeDependencies();
    runApp(const MyAppClean());
  } else {
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ProjectStore()),
          ChangeNotifierProvider(create: (_) => SessionStore()),
        ],
        child: const MyAppLegacy(),
      ),
    );
  }
}

/// Clean Architecture version of the app (with BLoC)
class MyAppClean extends StatelessWidget {
  const MyAppClean({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RoadMind Phone - Clean',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: ThemeMode.dark,
      home: BlocProvider(
        create: (_) => sl<ProjectBloc>(),
        child: const ProjectListPage(),
      ),
    );
  }
}

/// Legacy version of the app (with Provider)
///
/// Kept for backward compatibility and gradual migration.
/// Uses the old MyHomePage from the original main.dart.
class MyAppLegacy extends StatelessWidget {
  const MyAppLegacy({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      showSemanticsDebugger: false,
      title: 'RoadMind Phone - Legacy',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.dark,
      home: const LegacyHomePage(),
    );
  }
}

/// Placeholder for legacy home page
///
/// This would be the old MyHomePage from main.dart
/// For now, shows a simple message directing to use Clean Architecture
class LegacyHomePage extends StatelessWidget {
  const LegacyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RoadMind Phone - Legacy Mode'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.info_outline, size: 64, color: Colors.orange),
              const SizedBox(height: 24),
              const Text(
                'Mode Compatibilité (Legacy)',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Cette version utilise l\'ancienne architecture avec Provider.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              const Text(
                'Pour utiliser la nouvelle architecture Clean avec BLoC :',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '1. Ouvrir lib/main.dart\n'
                '2. Changer USE_CLEAN_ARCHITECTURE à true\n'
                '3. Redémarrer l\'application',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Navigate to old project list when needed
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'L\'ancienne page sera disponible si nécessaire',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.folder),
                label: const Text('Voir les projets (à venir)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
