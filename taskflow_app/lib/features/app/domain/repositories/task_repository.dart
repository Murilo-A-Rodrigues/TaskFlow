import '../entities/task.dart';

/// Interface do repositório de tarefas
/// Define os contratos para acesso aos dados
abstract class TaskRepository {
  Future<List<Task>> getAllTasks();
  Future<Task> createTask(Task task);
  Future<Task> updateTask(Task task);
  Future<void> deleteTask(String taskId);
  Future<Task?> getTaskById(String taskId);
  Future<void> clearAllTasks();
  Future<void> forceSyncAll();
}