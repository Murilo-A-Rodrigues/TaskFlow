import '../../domain/repositories/task_repository.dart';

/// Use Case para deletar uma tarefa
class DeleteTaskUseCase {
  final TaskRepository repository;

  DeleteTaskUseCase(this.repository);

  /// Executa a remoção de uma tarefa
  Future<void> execute(String taskId) async {
    if (taskId.trim().isEmpty) {
      throw ArgumentError('ID da tarefa inválido');
    }

    await repository.deleteTask(taskId);
  }
}
