import 'package:flutter/material.dart';
import '../../tasks/application/task_service.dart';

/// Widget que exibe dicas e progresso para novos usuários
/// Aparece apenas quando o usuário tem menos de 3 tarefas criadas
class FirstStepsCard extends StatelessWidget {
  final TaskService taskService;
  final VoidCallback? onCreateTaskPressed;

  const FirstStepsCard({
    super.key,
    required this.taskService,
    this.onCreateTaskPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Só mostra se o usuário tem menos de 3 tarefas criadas
    if (taskService.totalTasks >= 3) {
      return const SizedBox.shrink();
    }

    final tasksRemaining = 3 - taskService.totalTasks;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor.withValues(alpha: 0.05),
              Theme.of(context).primaryColor.withValues(alpha: 0.02),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.trending_up,
                      color: Theme.of(context).primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Primeiros Passos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Text(
                'Crie suas primeiras $tasksRemaining tarefas do dia para começar a organizar sua produtividade!',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.8),
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 20),

              LinearProgressIndicator(
                value: taskService.totalTasks / 3,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
                minHeight: 6,
              ),

              const SizedBox(height: 12),

              Text(
                '${taskService.totalTasks}/3 tarefas criadas',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
