import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';

/// Use Case para obter uma tarefa por ID
class GetTaskByIdUseCase {
  final TaskRepository repository;

  GetTaskByIdUseCase(this.repository);

  /// Executa a busca de uma tarefa por ID
  Future<Task?> execute(String taskId) async {
    if (taskId.trim().isEmpty) {
      throw ArgumentError('ID da tarefa inválido');
    }

    return await repository.getTaskById(taskId);
  }
}
