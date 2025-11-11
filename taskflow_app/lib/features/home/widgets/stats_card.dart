import 'package:flutter/material.dart';
import '../../../services/core/task_service_v2.dart';

/// Widget que exibe as estatísticas das tarefas em formato de card
/// Mostra total, pendentes, concluídas e progresso visual
class StatsCard extends StatelessWidget {
  final TaskService taskService;

  const StatsCard({
    super.key,
    required this.taskService,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatItem(
                  context,
                  'Total',
                  taskService.totalTasks.toString(),
                  Icons.assignment,
                  const Color(0xFF3B82F6), // Blue com melhor contraste
                ),
                const SizedBox(width: 8),
                _buildStatItem(
                  context,
                  'Pendentes',
                  taskService.pendingTasksCount.toString(),
                  Icons.pending,
                  const Color(0xFFF59E0B), // Orange com melhor contraste
                ),
                const SizedBox(width: 8),
                _buildStatItem(
                  context,
                  'Concluídas',
                  taskService.completedTasksCount.toString(),
                  Icons.check_circle,
                  const Color(0xFF10B981), // Green com melhor contraste
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (taskService.totalTasks > 0) ...[
              Text(
                'Progresso: ${(taskService.completionPercentage * 100).toStringAsFixed(1)}%',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: taskService.completionPercentage,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon, 
                color: color.withValues(alpha: 0.8), 
                size: 24,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.0,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}