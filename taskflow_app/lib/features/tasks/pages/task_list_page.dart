import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/domain/entities/task.dart';
import '../../../services/core/task_service_v2.dart';
import '../widgets/task_form_dialog.dart';
import '../widgets/task_card.dart';

/// Página de listagem de tarefas com estado vazio acolhedor
/// 
/// Implementa o Prompt 04 - Layout com:
/// - Estado vazio com ilustração e mensagem
/// - FAB com microanimação
/// - Tip Bubble (dica flutuante)
/// - Overlay de tutorial
class TaskListPage extends StatefulWidget {
  const TaskListPage({super.key});

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {

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
      body: Stack(
        children: [
          // Conteúdo principal
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

  Future<void> _refreshTasks() async {
    await context.read<TaskService>().forceSyncAll();
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
