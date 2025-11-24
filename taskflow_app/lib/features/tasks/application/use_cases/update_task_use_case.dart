import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';

/// Use Case para atualizar uma tarefa existente
class UpdateTaskUseCase {
  final TaskRepository repository;

  UpdateTaskUseCase(this.repository);

  /// Executa a atualização de uma tarefa
  /// 
  /// Valida os dados e delega ao repositório
  Future<Task> execute(Task task) async {
    // Validações de negócio
    if (task.title.trim().isEmpty) {
      throw ArgumentError('O título da tarefa não pode ser vazio');
    }

    if (task.title.length > 200) {
      throw ArgumentError('O título da tarefa não pode exceder 200 caracteres');
    }

    // Atualiza o timestamp
    final updatedTask = task.copyWith(
      updatedAt: DateTime.now(),
    );

    // Delega ao repositório
    return await repository.updateTask(updatedTask);
  }
}
