import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roadmindphone/core/di/injection_container.dart';
import 'package:roadmindphone/features/project/presentation/bloc/project_bloc.dart';
import 'package:roadmindphone/features/project/presentation/pages/pages.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Main entry point of the application
///
/// Initializes dependencies and runs the app with Clean Architecture
/// and BLoC pattern for state management.
Future<void> main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize sqflite for desktop platforms
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Initialize all dependencies (DI container)
  await initializeDependencies();

  // Run the app
  runApp(const MyApp());
}

/// Root application widget
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RoadMind Phone',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: ThemeMode.dark,
      // Provide ProjectBloc at the root level
      home: BlocProvider(
        create: (_) => sl<ProjectBloc>(),
        child: const ProjectListPage(),
      ),
    );
  }
}
