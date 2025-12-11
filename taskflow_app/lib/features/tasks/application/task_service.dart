import 'package:flutter/foundation.dart';
import '../domain/entities/task.dart';
import '../domain/entities/task_priority.dart';
import '../domain/repositories/task_repository.dart';
import '../../auth/application/auth_service.dart';

/// TaskService - Camada de serviço usando arquitetura Entity/DTO/Mapper
///
/// Esta versão segue o padrão do documento "Modelo DTO e Mapeamento":
/// - Consome apenas Task Entities (formato interno limpo)
/// - Repository abstrai DTOs e conversões
/// - UI recebe dados sempre validados e formatados
/// - Separação clara de responsabilidades
class TaskService extends ChangeNotifier {
  final TaskRepository _repository;
  final AuthService _authService;
  final List<Task> _tasks = [];
  bool _isInitialized = false;
  bool _isSyncing = false;

  // Injeção de dependência via construtor (padrão correto do documento)
  TaskService(this._repository, this._authService) {
    initializeTasks();
  }

  /// Inicializa o serviço carregando tarefas
  /// Repository retorna Entities prontas para consumo
  Future<void> initializeTasks() async {
    if (_isInitialized) return;

    try {
      print('🚀 Inicializando TaskService...');

      // Repository abstrai toda complexidade DTO/Entity
      final entities = await _repository.getAllTasks();
      _tasks.clear();
      _tasks.addAll(entities);

      print('📋 TaskService inicializado com ${_tasks.length} tarefas');
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      print('❌ Erro ao inicializar TaskService: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Adiciona nova tarefa
  /// Entity é passada para o repository, que cuida da conversão
  Future<void> addTask(Task entity) async {
    try {
      print('➕ Adicionando tarefa: ${entity.title}');

      // Optimistic update - adiciona à lista local imediatamente
      _tasks.add(entity);
      notifyListeners();

      // Repository cuida de DTO/conversões
      final createdEntity = await _repository.createTask(entity);

      // Atualiza com dados do servidor (pode ter ID/timestamps diferentes)
      final index = _tasks.indexWhere((t) => t.id == entity.id);
      if (index != -1) {
        _tasks[index] = createdEntity;
      }

      await _refreshTasks();
    } catch (e) {
      print('❌ Erro ao adicionar tarefa: $e');
      // Remove da lista local em caso de erro
      _tasks.removeWhere((t) => t.id == entity.id);
      notifyListeners();
    }
  }

  /// Atualiza tarefa existente
  Future<void> updateTask(Task updatedEntity) async {
    try {
      print('✏️ Atualizando tarefa: ${updatedEntity.title}');

      // Optimistic update
      final index = _tasks.indexWhere((task) => task.id == updatedEntity.id);
      if (index != -1) {
        _tasks[index] = updatedEntity;
        notifyListeners();
      }

      // Repository cuida das conversões e persistência
      final result = await _repository.updateTask(updatedEntity);

      // Confirma com dados do servidor
      final serverIndex = _tasks.indexWhere((t) => t.id == result.id);
      if (serverIndex != -1) {
        _tasks[serverIndex] = result;
      }

      await _refreshTasks();
    } catch (e) {
      print('❌ Erro ao atualizar tarefa: $e');
      await _refreshTasks(); // Reverte optimistic update
    }
  }

  /// Remove tarefa
  Future<void> deleteTask(String taskId) async {
    try {
      print('🗑️ Removendo tarefa: $taskId');

      // Optimistic update
      _tasks.removeWhere((task) => task.id == taskId);
      notifyListeners();

      // Repository cuida da persistência
      await _repository.deleteTask(taskId);

      await _refreshTasks();
    } catch (e) {
      print('❌ Erro ao remover tarefa: $e');
      await _refreshTasks(); // Reverte optimistic update
    }
  }

  /// Alterna status de conclusão da tarefa
  Future<void> toggleTaskComplete(String taskId) async {
    try {
      final task = _tasks.firstWhere(
        (task) => task.id == taskId,
        orElse: () => throw Exception('Tarefa não encontrada'),
      );
      final updatedTask = task.copyWith(isCompleted: !task.isCompleted);
      await updateTask(updatedTask);
    } catch (e) {
      print('❌ Erro ao alternar conclusão da tarefa: $e');
    }
  }

  /// Alias para compatibilidade
  Future<void> toggleTaskCompletion(String taskId) async {
    await toggleTaskComplete(taskId);
  }

  /// Carrega tarefas de exemplo
  /// Usa Entities diretamente (conforme padrão do documento)
  Future<void> loadSampleTasks() async {
    try {
      print('📄 Carregando tarefas de exemplo...');

      // Obtém o userId do usuário autenticado
      final userId = _authService.userId;
      if (userId == null) {
        print('❌ Usuário não autenticado, não é possível criar tarefas de exemplo');
        return;
      }

      // Tarefas de exemplo usando Entity diretamente (não DTO)
      final sampleTasks = [
        Task(
          id: 'sample-1',
          title: 'Configurar ambiente de desenvolvimento',
          description: 'Instalar Flutter, VS Code e dependências necessárias',
          isCompleted: true,
          priority: TaskPriority.high,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          updatedAt: DateTime.now(),
          dueDate: DateTime.now().subtract(const Duration(days: 1)),
          userId: userId,
        ),
        Task(
          id: 'sample-2',
          title: 'Implementar tela de login',
          description: 'Criar formulário de autenticação com validação',
          isCompleted: false,
          priority: TaskPriority.medium,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          updatedAt: DateTime.now(),
          dueDate: DateTime.now().add(const Duration(days: 3)),
          userId: userId,
        ),
        Task(
          id: 'sample-3',
          title: 'Configurar integração com backend',
          description: 'Implementar chamadas API e tratamento de erros',
          isCompleted: false,
          priority: TaskPriority.high,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          dueDate: DateTime.now().add(const Duration(days: 7)),
          userId: userId,
        ),
      ];

      for (final task in sampleTasks) {
        await _repository.createTask(task);
      }

      await _refreshTasks();
      print('📋 ${sampleTasks.length} tarefas de exemplo adicionadas');
    } catch (e) {
      print('❌ Erro ao carregar tarefas de exemplo: $e');
    }
  }

  /// Remove todas as tarefas
  Future<void> clearAllTasks() async {
    try {
      print('🧹 Removendo todas as tarefas...');

      // Optimistic update
      _tasks.clear();
      notifyListeners();

      // Repository cuida da limpeza completa
      await _repository.clearAllTasks();

      print('✅ Todas as tarefas removidas');
    } catch (e) {
      print('❌ Erro ao limpar tarefas: $e');
      await _refreshTasks(); // Reverte em caso de erro
    }
  }

  /// Força sincronização completa
  Future<void> forceSyncAll() async {
    _isSyncing = true;
    notifyListeners();

    try {
      print('🔄 Forçando sincronização completa...');

      // Repository cuida de toda lógica de sync
      await _repository.forceSyncAll();
      await _refreshTasks();

      print('✅ Sincronização completa finalizada');
    } catch (e) {
      print('❌ Erro na sincronização: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Recarrega tarefas do repository
  /// Repository retorna Entities já convertidas
  Future<void> _refreshTasks() async {
    try {
      // Repository abstrai toda complexidade DTO/Entity
      final entities = await _repository.getAllTasks();
      _tasks.clear();
      _tasks.addAll(entities);
      notifyListeners();
    } catch (e) {
      print('❌ Erro ao atualizar tarefas: $e');
    }
  }

  // ==================== GETTERS E PROPRIEDADES ====================

  /// Lista imutável de tarefas (todas Entities)
  List<Task> get tasks => List.unmodifiable(_tasks);

  bool get isInitialized => _isInitialized;
  bool get isSyncing => _isSyncing;

  /// Tarefas concluídas
  List<Task> get completedTasks =>
      _tasks.where((task) => task.isCompleted).toList();

  /// Tarefas pendentes
  List<Task> get pendingTasks =>
      _tasks.where((task) => !task.isCompleted).toList();

  /// Estatísticas numéricas
  int get totalTasks => _tasks.length;
  int get completedTasksCount => completedTasks.length;
  int get pendingTasksCount => pendingTasks.length;

  /// Percentual de conclusão
  double get completionPercentage {
    if (_tasks.isEmpty) return 0.0;
    return completedTasksCount / totalTasks;
  }

  /// Mapa com estatísticas
  Map<String, int> get taskStats => {
    'total': totalTasks,
    'completed': completedTasksCount,
    'pending': pendingTasksCount,
  };

  // ==================== MÉTODOS DE FILTRO E BUSCA ====================

  /// Filtra tarefas por prioridade
  List<Task> getTasksByPriority(TaskPriority priority) {
    return _tasks.where((task) => task.priority == priority).toList();
  }

  /// Busca tarefas por texto
  List<Task> searchTasks(String query) {
    if (query.isEmpty) return tasks;

    final lowercaseQuery = query.toLowerCase();
    return _tasks
        .where(
          (task) =>
              task.title.toLowerCase().contains(lowercaseQuery) ||
              task.description.toLowerCase().contains(lowercaseQuery),
        )
        .toList();
  }

  /// Tarefas atrasadas (Entity tem getter isOverdue)
  List<Task> get overdueTasks =>
      _tasks.where((task) => task.isOverdue).toList();

  /// Tarefas que vencem hoje (Entity tem getter isDueToday)
  List<Task> get tasksDueToday =>
      _tasks.where((task) => task.isDueToday).toList();

  /// Tarefas por status com uso das conveniências da Entity
  Map<String, List<Task>> get tasksByStatus => {
    'completed': completedTasks,
    'pending': pendingTasks,
    'overdue': overdueTasks,
    'due_today': tasksDueToday,
  };
}
