import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../data/sample_data.dart';

class TaskService extends ChangeNotifier {
  final List<Task> _tasks = [];
  
  TaskService() {
    // Adiciona dados de exemplo na inicialização
    _tasks.addAll(SampleData.getSampleTasks());
  }

  List<Task> get tasks => List.unmodifiable(_tasks);

  List<Task> get completedTasks => _tasks.where((task) => task.isCompleted).toList();

  List<Task> get pendingTasks => _tasks.where((task) => !task.isCompleted).toList();

  int get totalTasks => _tasks.length;

  int get completedTasksCount => completedTasks.length;

  int get pendingTasksCount => pendingTasks.length;

  double get completionPercentage {
    if (_tasks.isEmpty) return 0.0;
    return completedTasksCount / totalTasks;
  }

  void addTask(Task task) {
    _tasks.add(task);
    notifyListeners();
  }

  void updateTask(Task updatedTask) {
    final index = _tasks.indexWhere((task) => task.id == updatedTask.id);
    if (index != -1) {
      _tasks[index] = updatedTask;
      notifyListeners();
    }
  }

  void deleteTask(String taskId) {
    _tasks.removeWhere((task) => task.id == taskId);
    notifyListeners();
  }

  void toggleTaskCompletion(String taskId) {
    final task = _tasks.firstWhere((task) => task.id == taskId);
    task.isCompleted = !task.isCompleted;
    notifyListeners();
  }

  List<Task> getTasksByPriority(TaskPriority priority) {
    return _tasks.where((task) => task.priority == priority).toList();
  }

  List<Task> searchTasks(String query) {
    if (query.isEmpty) return tasks;
    
    return _tasks.where((task) =>
      task.title.toLowerCase().contains(query.toLowerCase()) ||
      task.description.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  void clearCompletedTasks() {
    _tasks.removeWhere((task) => task.isCompleted);
    notifyListeners();
  }

  // Métodos para persistência local (simulados)
  String toJson() {
    return jsonEncode(_tasks.map((task) => task.toJson()).toList());
  }

  void fromJson(String jsonString) {
    final List<dynamic> jsonList = jsonDecode(jsonString);
    _tasks.clear();
    _tasks.addAll(jsonList.map((json) => Task.fromJson(json)));
    notifyListeners();
  }
}