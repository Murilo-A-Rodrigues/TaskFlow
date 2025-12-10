import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';

/// Use Case para criar uma nova tarefa
class CreateTaskUseCase {
  final TaskRepository repository;

  CreateTaskUseCase(this.repository);

  /// Executa a criação de uma tarefa
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

    // Delega ao repositório
    return await repository.createTask(task);
  }
}
