import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';

/// Use Case para obter todas as tarefas
class GetAllTasksUseCase {
  final TaskRepository repository;

  GetAllTasksUseCase(this.repository);

  /// Executa a busca de todas as tarefas
  Future<List<Task>> execute() async {
    return await repository.getAllTasks();
  }
}
