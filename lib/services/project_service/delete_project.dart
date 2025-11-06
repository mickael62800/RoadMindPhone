import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roadmindphone/features/project/domain/entities/project_entity.dart';
import 'package:roadmindphone/features/project/presentation/bloc/project_bloc.dart';
import 'package:roadmindphone/features/project/presentation/bloc/project_event.dart';
import 'package:roadmindphone/features/project/presentation/bloc/project_state.dart';

Future<bool> deleteProject({
  required BuildContext context,
  required String projectId,
}) async {
  final projectBloc = context.read<ProjectBloc>();
  final messenger = ScaffoldMessenger.of(context);
  projectBloc.add(DeleteProjectEvent(projectId: projectId));
  await for (final state in projectBloc.stream) {
    if (state is ProjectOperationSuccess) {
      messenger.showSnackBar(const SnackBar(content: Text('Projet supprimé')));
      return true;
    } else if (state is ProjectError) {
      messenger.showSnackBar(
        SnackBar(content: Text('Erreur: ${state.message}')),
      );
      return false;
    }
  }
  return false;
}
