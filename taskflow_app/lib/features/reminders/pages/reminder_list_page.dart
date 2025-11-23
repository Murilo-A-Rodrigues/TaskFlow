import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/core/reminder_service.dart';
import '../../../services/core/task_service_v2.dart';
import '../../../features/app/domain/entities/reminder.dart';
import '../widgets/reminder_form_dialog.dart';

/// ReminderListPage - Tela de listagem de lembretes
/// 
/// Exibe todos os lembretes agrupados por tarefa
/// Permite editar, excluir e ativar/desativar lembretes
class ReminderListPage extends StatelessWidget {
  const ReminderListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Lembretes'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
      body: Consumer2<ReminderService, TaskService>(
        builder: (context, reminderService, taskService, child) {
          final reminders = reminderService.reminders;

          if (reminders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 80,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhum lembrete criado',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Crie lembretes para suas tarefas importantes',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ],
              ),
            );
          }

          // Agrupa lembretes por tarefa
          final remindersByTask = <String, List<Reminder>>{};
          for (final reminder in reminders) {
            remindersByTask.putIfAbsent(reminder.taskId, () => []).add(reminder);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: remindersByTask.length,
            itemBuilder: (context, index) {
              final taskId = remindersByTask.keys.elementAt(index);
              final taskReminders = remindersByTask[taskId]!;
              
              // Busca tarefa na lista
              final task = taskService.tasks.cast<dynamic>().firstWhere(
                (t) => t.id == taskId,
                orElse: () => null,
              );

              if (task == null) {
                // Tarefa foi deletada, mas lembretes ainda existem
                return const SizedBox.shrink();
              }

              return _TaskReminderGroup(
                task: task,
                reminders: taskReminders,
              );
            },
          );
        },
      ),
    );
  }
}

/// Widget que agrupa lembretes de uma tarefa
class _TaskReminderGroup extends StatelessWidget {
  final dynamic task;
  final List<Reminder> reminders;

  const _TaskReminderGroup({
    required this.task,
    required this.reminders,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header da tarefa
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  task.isCompleted ? Icons.check_circle : Icons.task_alt,
                  color: task.isCompleted
                      ? Colors.green
                      : Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      if (task.dueDate != null)
                        Text(
                          'Prazo: ${_formatDate(task.dueDate)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(
                    '${reminders.length}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),

          // Lista de lembretes
          ...reminders.map((reminder) => _ReminderTile(
                reminder: reminder,
                task: task,
              )),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

/// Widget individual de lembrete
class _ReminderTile extends StatelessWidget {
  final Reminder reminder;
  final dynamic task;

  const _ReminderTile({
    required this.reminder,
    required this.task,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isPast = reminder.reminderDate.isBefore(now);

    return ListTile(
      leading: Icon(
        _getTypeIcon(reminder.type),
        color: reminder.isActive
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.outline,
      ),
      title: Text(
        reminder.customMessage ?? 'Lembrete: ${task.title}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: reminder.isActive ? null : Theme.of(context).colorScheme.outline,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatDateTime(reminder.reminderDate),
            style: TextStyle(
              color: isPast && reminder.isActive ? Colors.orange : null,
            ),
          ),
          Row(
            children: [
              Chip(
                label: Text(
                  reminder.type.label,
                  style: const TextStyle(fontSize: 10),
                ),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
              if (!reminder.isActive) ...[
                const SizedBox(width: 8),
                const Chip(
                  label: Text(
                    'Inativo',
                    style: TextStyle(fontSize: 10),
                  ),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
              ],
            ],
          ),
        ],
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) => _handleMenuAction(context, value),
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'toggle',
            child: Row(
              children: [
                Icon(
                  reminder.isActive ? Icons.notifications_off : Icons.notifications_active,
                ),
                const SizedBox(width: 12),
                Text(reminder.isActive ? 'Desativar' : 'Ativar'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit),
                SizedBox(width: 12),
                Text('Editar'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete, color: Colors.red),
                SizedBox(width: 12),
                Text('Excluir', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    final reminderService = context.read<ReminderService>();

    switch (action) {
      case 'toggle':
        reminderService.toggleReminder(reminder.id, task);
        break;

      case 'edit':
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => ReminderFormDialog(
            task: task,
            reminder: reminder,
          ),
        );
        break;

      case 'delete':
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Excluir Lembrete'),
            content: const Text(
              'Tem certeza que deseja excluir este lembrete?\n\n'
              'Esta ação não pode ser desfeita.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await reminderService.deleteReminder(reminder.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Lembrete excluído'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text('Excluir'),
              ),
            ],
          ),
        );
        break;
    }
  }

  IconData _getTypeIcon(ReminderType type) {
    switch (type) {
      case ReminderType.once:
        return Icons.notifications;
      case ReminderType.daily:
        return Icons.today;
      case ReminderType.weekly:
        return Icons.date_range;
      case ReminderType.monthly:
        return Icons.calendar_month;
    }
  }

  String _formatDateTime(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now);

    if (diff.isNegative) {
      if (diff.inDays < -1) {
        return 'Passou há ${-diff.inDays} dias';
      } else if (diff.inDays == -1) {
        return 'Passou ontem';
      } else {
        return 'Passou hoje às ${_formatTime(date)}';
      }
    } else {
      if (diff.inDays == 0) {
        return 'Hoje às ${_formatTime(date)}';
      } else if (diff.inDays == 1) {
        return 'Amanhã às ${_formatTime(date)}';
      } else if (diff.inDays < 7) {
        return 'Em ${diff.inDays} dias às ${_formatTime(date)}';
      } else {
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} às ${_formatTime(date)}';
      }
    }
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
