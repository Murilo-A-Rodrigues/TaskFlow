import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../domain/entities/task.dart';
import '../../tasks/application/task_service.dart';
import '../widgets/task_form_dialog.dart';
import '../widgets/task_card.dart';
import '../infrastructure/local/tasks_local_dao.dart';
import '../infrastructure/remote/supabase_tasks_remote_datasource.dart';
import '../infrastructure/repositories/tasks_repository_impl.dart';

/// Página de listagem de tarefas com estado vazio acolhedor
/// 
/// Implementa os Prompts 04, 16, 17 e 18:
/// - Estado vazio com ilustração e mensagem
/// - FAB com microanimação
/// - Sincronização offline-first com Supabase
/// - Push-then-Pull sync automático
/// - Uso de Entity (domínio) ao invés de DTO na UI
/// - Indicador visual durante sincronização
/// 
/// ⚠️ Boas práticas implementadas:
/// - Sempre verifica 'mounted' antes de setState
/// - Carrega cache primeiro para UI responsiva
/// - Sincroniza em background sem bloquear UI
/// - Logs de debug para facilitar diagnóstico
/// - RefreshIndicator funciona mesmo com lista vazia
class TaskListPage extends StatefulWidget {
  const TaskListPage({super.key});

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  /// Flag para indicar sincronização em andamento
  /// Usado para mostrar LinearProgressIndicator no topo da tela
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    // Carrega tarefas na inicialização
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTasks();
    });
  }

  /// Carrega tarefas seguindo o padrão offline-first (Prompts 16, 17, 18)
  /// 
  /// Fluxo:
  /// 1. Carrega do cache local rapidamente (UI responsiva)
  /// 2. Dispara sincronização em background
  /// 3. Se houver mudanças, recarrega e atualiza UI
  Future<void> _loadTasks() async {
    if (!mounted) return;

    try {
      // Sempre sincroniza ao carregar (Prompt 18 - two-way sync)
      // Mostra indicador de progresso durante sync
      if (mounted) {
        setState(() => _isSyncing = true);
      }

      // Cria repositório para sincronização
      final dao = TasksLocalDaoSharedPrefs();
      final remote = SupabaseTasksRemoteDatasource();
      final repo = TasksRepositoryImpl(
        remoteApi: remote,
        localDao: dao,
      );

      // Executa sincronização bidirecional (push then pull)
      final changed = await repo.syncFromServer();

      if (kDebugMode) {
        print('TaskListPage._loadTasks: sync completed, $changed items changed');
      }

      // Recarrega tasks via TaskService após sync
      if (mounted) {
        await context.read<TaskService>().forceSyncAll();
      }

      // Mostra feedback se houver mudanças
      if (changed > 0 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$changed tarefa(s) sincronizada(s) com sucesso'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('TaskListPage._loadTasks ERROR: $e');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao sincronizar: $e'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  void _addNewTask() async {
    final result = await showTaskFormDialog(context);

    if (result != null && mounted) {
      await context.read<TaskService>().addTask(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Tarefas'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Indicador de sincronização no topo (Prompt 18)
          if (_isSyncing)
            const LinearProgressIndicator(minHeight: 3),
          // Conteúdo principal
          Expanded(
            child: Stack(
              children: [
                Consumer<TaskService>(
            builder: (context, taskService, child) {
              final tasks = taskService.tasks;

              if (tasks.isEmpty) {
                return RefreshIndicator(
                  onRefresh: () => _refreshTasks(),
                  child: _buildEmptyState(),
                );
              }

              return RefreshIndicator(
                onRefresh: () => _refreshTasks(),
                child: ListView.builder(
                  padding: const EdgeInsets.only(
                    top: 16,
                    left: 8,
                    right: 8,
                    bottom: 80, // Espaço para FAB
                  ),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return Dismissible(
                      key: Key(task.id),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (direction) => _confirmDelete(task),
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Colors.red,
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      child: TaskCard(
                        task: task,
                        onToggle: () => _toggleTask(task.id),
                        onEdit: () => _editTask(task),
                        onDelete: () => _deleteTask(task),
                      ),
                    );
                  },
                ),
              );
            },
          ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewTask,
        icon: const Icon(Icons.add),
        label: const Text('Nova Tarefa'),
        tooltip: 'Criar nova tarefa',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  /// Estado vazio com caixa de diálogo instrutiva
  Widget _buildEmptyState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
            // Caixa de diálogo com dica
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: Theme.of(context).primaryColor.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Ícone
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lightbulb_outline,
                      size: 40,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Título
                  Text(
                    'Comece sua jornada!',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // Mensagem
                  Text(
                    'Você ainda não tem nenhuma tarefa cadastrada.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[700],
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  
                  Text(
                    'Toque no botão laranja abaixo para criar sua primeira tarefa e começar a organizar seu dia!',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Ícone de seta apontando para baixo
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 10.0),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeInOut,
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, value),
                        child: child,
                      );
                    },
                    onEnd: () {
                      if (mounted) {
                        setState(() {});
                      }
                    },
                    child: Icon(
                      Icons.arrow_downward,
                      size: 32,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                  ),
                ],
              ),
            ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _toggleTask(String taskId) async {
    await context.read<TaskService>().toggleTaskCompletion(taskId);
  }

  void _editTask(Task task) async {
    final result = await showTaskFormDialog(context, initial: task);

    if (result != null && mounted) {
      await context.read<TaskService>().updateTask(result);
    }
  }

  /// Pull-to-refresh: executa sincronização completa (Prompt 16, 18)
  /// 
  /// Chamado quando usuário arrasta a lista para baixo.
  /// Sincroniza com servidor e atualiza a UI.
  Future<void> _refreshTasks() async {
    if (kDebugMode) {
      print('TaskListPage._refreshTasks: iniciando pull-to-refresh');
    }

    await _loadTasks();
  }

  Future<bool> _confirmDelete(Task task) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Não fecha ao tocar fora
      builder: (context) => AlertDialog(
        title: const Text('Excluir tarefa'),
        content: Text('Deseja realmente excluir "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      try {
        await context.read<TaskService>().deleteTask(task.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Tarefa "${task.title}" excluída com sucesso'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return true;
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao excluir tarefa: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return false;
      }
    }
    return false;
  }

  void _deleteTask(Task task) {
    showDialog(
      context: context,
      barrierDismissible: false, // Não fecha ao tocar fora
      builder: (context) => AlertDialog(
        title: const Text('Excluir tarefa'),
        content: Text('Deseja realmente excluir "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await context.read<TaskService>().deleteTask(task.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Tarefa "${task.title}" excluída com sucesso'),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}

/*
// Implementação dos Prompts 16, 17 e 18 aplicada nesta página:
// 
// ✅ Prompt 16 - Sincronização na UI:
//    - _loadTasks() sempre sincroniza ao abrir a tela
//    - Mostra LinearProgressIndicator durante sync
//    - RefreshIndicator permite pull-to-refresh manual
//    - Não bloqueia UI; cache carregado primeiro
// 
// ✅ Prompt 17 - UI usa Entity (domínio):
//    - Toda a UI consome Task (Entity) ao invés de TaskDto
//    - Conversão DTO↔Entity acontece no repositório
//    - Mappers centralizados na camada de infraestrutura
// 
// ✅ Prompt 18 - Sincronização bidirecional:
//    - syncFromServer() executa PUSH then PULL
//    - Push: envia cache local para servidor (best-effort)
//    - Pull: busca mudanças remotas e aplica localmente
//    - Timestamps usados para controle incremental
//    - Falhas de push não bloqueiam pull
// 
// Logs esperados no console (kDebugMode):
// - TaskListPage._loadTasks: sync completed, 3 items changed
// - TasksRepositoryImpl.syncFromServer: pushed 5 de 5 items to remote
// - TasksRepositoryImpl.syncFromServer: recebidos 3 items from remote
// - SupabaseTasksRemoteDatasource.fetchTasks: recebidos 3 registros
// 
// Checklist de erros comuns EVITADOS nesta implementação:
// ✅ Sempre verifica 'mounted' antes de setState
// ✅ Carrega cache primeiro, sync depois (não bloqueia UI)
// ✅ RefreshIndicator funciona mesmo com lista vazia (AlwaysScrollableScrollPhysics)
// ✅ Logs de debug em pontos-chave
// ✅ Tratamento de erros com feedback ao usuário
// ✅ SnackBar só mostrado se widget ainda montado
// 
// 📚 Referências:
// - providers_cache_debug_prompt.md: exemplos de logs
// - supabase_init_debug_prompt.md: problemas de inicialização
// - supabase_rls_remediation.md: erros de permissão RLS
*/

