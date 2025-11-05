import 'package:flutter/foundation.dart';
import '../../models/task.dart';
import '../../data/sample_data.dart';
import '../../repositories/task_repository.dart';

class TaskService extends ChangeNotifier {
  final TaskRepository _repository = TaskRepository();
  final List<Task> _tasks = [];
  bool _isInitialized = false;
  bool _isSyncing = false;
  
  TaskService() {
    initializeTasks();
  }

  Future<void> initializeTasks() async {
    if (_isInitialized) return;
    
    try {
      final tasks = await _repository.getAllTasks();
      _tasks.clear();
      _tasks.addAll(tasks);
      
      print('📋 TaskService inicializado com ${_tasks.length} tarefas');
      _isInitialized = true;
      notifyListeners();
      
    } catch (e) {
      print('❌ Erro ao inicializar TaskService: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> addTask(Task task) async {
    _tasks.add(task);
    notifyListeners();
    
    await _repository.createTask(task);
    await _refreshTasks();
  }

  Future<void> updateTask(Task updatedTask) async {
    final index = _tasks.indexWhere((task) => task.id == updatedTask.id);
    if (index != -1) {
      _tasks[index] = updatedTask;
      notifyListeners();
      
      await _repository.updateTask(updatedTask);
      await _refreshTasks();
    }
  }

  Future<void> deleteTask(String taskId) async {
    _tasks.removeWhere((task) => task.id == taskId);
    notifyListeners();
    
    await _repository.deleteTask(taskId);
    await _refreshTasks();
  }

  Future<void> toggleTaskComplete(String taskId) async {
    final task = _tasks.firstWhere((task) => task.id == taskId);
    final updatedTask = task.copyWith(isCompleted: !task.isCompleted);
    await updateTask(updatedTask);
  }

  Future<void> toggleTaskCompletion(String taskId) async {
    await toggleTaskComplete(taskId);
  }

  Future<void> clearAllTasks() async {
    _tasks.clear();
    notifyListeners();
    
    await _repository.clearAllTasks();
    print('📋 Todas as tarefas foram removidas');
  }

  Future<void> loadSampleTasks() async {
    final sampleTasks = SampleData.getSampleTasks();
    
    for (final task in sampleTasks) {
      await _repository.createTask(task);
    }
    
    await _refreshTasks();
    print('📋 ${sampleTasks.length} tarefas de exemplo adicionadas');
  }

  Future<void> _refreshTasks() async {
    try {
      final tasks = await _repository.getAllTasks();
      _tasks.clear();
      _tasks.addAll(tasks);
      notifyListeners();
    } catch (e) {
      print('❌ Erro ao atualizar tarefas: $e');
    }
  }

  Future<void> forceSyncAll() async {
    _isSyncing = true;
    notifyListeners();
    
    try {
      await _repository.forceSyncAll();
      await _refreshTasks();
    } catch (e) {
      print('❌ Erro na sincronização: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  List<Task> get tasks => List.unmodifiable(_tasks);
  bool get isInitialized => _isInitialized;
  bool get isSyncing => _isSyncing;

  List<Task> get completedTasks => _tasks.where((task) => task.isCompleted).toList();
  List<Task> get pendingTasks => _tasks.where((task) => !task.isCompleted).toList();

  int get totalTasks => _tasks.length;
  int get completedTasksCount => completedTasks.length;
  int get pendingTasksCount => pendingTasks.length;

  double get completionPercentage {
    if (_tasks.isEmpty) return 0.0;
    return completedTasksCount / totalTasks;
  }

  Map<String, int> get taskStats => {
    'total': totalTasks,
    'completed': completedTasksCount,
    'pending': pendingTasksCount,
  };

  List<Task> getTasksByPriority(TaskPriority priority) {
    return _tasks.where((task) => task.priority == priority).toList();
  }

  List<Task> searchTasks(String query) {
    if (query.isEmpty) return tasks;
    
    final lowercaseQuery = query.toLowerCase();
    return _tasks.where((task) =>
      task.title.toLowerCase().contains(lowercaseQuery) ||
      task.description.toLowerCase().contains(lowercaseQuery)
    ).toList();
  }
}
