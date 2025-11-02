import 'package:equatable/equatable.dart';
import 'package:roadmindphone/core/usecases/usecase.dart';
import 'package:roadmindphone/core/utils/typedef.dart';
import 'package:roadmindphone/features/project/domain/entities/project_entity.dart';
import 'package:roadmindphone/features/project/domain/repositories/project_repository.dart';

/// Use case for creating a new project
///
/// This use case encapsulates the business logic for project creation.
/// It validates the input and delegates to the repository.
class CreateProject implements UseCase<ProjectEntity, CreateProjectParams> {
  final ProjectRepository _repository;

  const CreateProject(this._repository);

  @override
  ResultFuture<ProjectEntity> call(CreateProjectParams params) async {
    return _repository.createProject(
      title: params.title,
      description: params.description,
    );
  }
}

/// Parameters for creating a project
class CreateProjectParams extends Equatable {
  final String title;
  final String? description;

  const CreateProjectParams({required this.title, this.description});

  @override
  List<Object?> get props => [title, description];
}
