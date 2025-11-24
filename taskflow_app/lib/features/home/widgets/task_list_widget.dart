import 'package:flutter/material.dart';
import '../../tasks/domain/entities/task.dart';
import '../../tasks/widgets/task_card.dart';

/// Widget que exibe a lista de tarefas com estado vazio
/// Adapta-se ao espaço disponível e exibe mensagens contextuais
class TaskListWidget extends StatelessWidget {
  final List<Task> tasks;
  final String searchQuery;
  final Function(String) onToggleTask;
  final Function(Task) onEditTask;
  final Function(Task) onDeleteTask;

  const TaskListWidget({
    super.key,
    required this.tasks,
    required this.searchQuery,
    required this.onToggleTask,
    required this.onEditTask,
    required this.onDeleteTask,
  });

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return TaskCard(
          task: task,
          onToggle: () => onToggleTask(task.id),
          onEdit: () => onEditTask(task),
          onDelete: () => onDeleteTask(task),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calcula o tamanho do ícone baseado na altura disponível
        final double availableHeight = constraints.maxHeight;
        final double iconSize = availableHeight > 150 ? 36 : 24;
        final double fontSize = availableHeight > 150 ? 14 : 12;
        final double smallFontSize = availableHeight > 150 ? 12 : 10;
        
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: availableHeight > 100 ? 80 : availableHeight * 0.8,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.task_alt,
                      size: iconSize,
                      color: Colors.grey.shade400,
                    ),
                    SizedBox(height: availableHeight > 150 ? 8 : 4),
                    Text(
                      searchQuery.isNotEmpty
                          ? 'Nenhuma tarefa encontrada'
                          : 'Nenhuma tarefa aqui',
                      style: TextStyle(
                        fontSize: fontSize,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: availableHeight > 150 ? 4 : 2),
                    Text(
                      searchQuery.isNotEmpty
                          ? 'Tente outro termo'
                          : 'Adicione uma tarefa',
                      style: TextStyle(
                        fontSize: smallFontSize,
                        color: Colors.grey.shade500,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
}
