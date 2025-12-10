import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../domain/entities/task.dart';
import '../domain/entities/task_priority.dart';
import '../../categories/application/category_service.dart';
import 'celebration_animation.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TaskCard({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: task.isCompleted,
                  onChanged: (_) {
                    // Se estiver marcando como completa, mostra animação de celebração
                    if (!task.isCompleted) {
                      showCelebrationAnimation(context);
                    }
                    onToggle();
                  },
                  activeColor: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFFFBBF24) // AMBER no dark mode
                      : Theme.of(context).primaryColor, // AZUL no light mode
                  checkColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors
                            .black // Check preto no dark mode para contraste
                      : Colors.white, // Check branco no light mode
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          color: task.isCompleted
                              ? Colors.grey
                              : Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      if (task.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          task.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: task.isCompleted
                                ? Colors.grey
                                : Theme.of(context).textTheme.bodyMedium?.color,
                            decoration: task.isCompleted
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        onEdit();
                        break;
                      case 'delete':
                        onDelete();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Excluir', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                // Chip de Prioridade
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(
                      task.priority,
                    ).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getPriorityColor(task.priority),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    task.priority.displayName,
                    style: TextStyle(
                      fontSize: 12,
                      color: _getPriorityColor(task.priority),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Chip de Categoria
                _buildCategoryChip(context),
                const Spacer(),
                if (task.dueDate != null) ...[
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: _getDueDateColor(task.dueDate!),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(task.dueDate!),
                    style: TextStyle(
                      fontSize: 12,
                      color: _getDueDateColor(task.dueDate!),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return Colors.green;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.high:
        return Colors.red;
    }
  }

  Color _getDueDateColor(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now).inDays;

    if (difference < 0) {
      return Colors.red; // Vencida
    } else if (difference == 0) {
      return Colors.orange; // Vence hoje
    } else if (difference <= 3) {
      return Colors.amber; // Vence em poucos dias
    } else {
      return Colors.grey; // Ainda tem tempo
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference < 0) {
      return 'Vencida';
    } else if (difference == 0) {
      return 'Hoje';
    } else if (difference == 1) {
      return 'Amanhã';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Widget _buildCategoryChip(BuildContext context) {
    if (task.categoryId == null) {
      // Sem categoria
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.label_off_outlined, size: 14, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              'Sem Categoria',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // Com categoria - buscar do CategoryService
    final categoryService = context.watch<CategoryService>();
    final category = categoryService.getCategoryById(task.categoryId!);

    if (category == null) {
      // Categoria não encontrada (deletada?)
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.label_off_outlined, size: 14, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              'Sem Categoria',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // Exibir categoria encontrada
    final categoryColor = _hexToColor(category.color);
    final categoryIcon = _getIconData(category.icon);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: categoryColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: categoryColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(categoryIcon, size: 14, color: categoryColor),
          const SizedBox(width: 4),
          Text(
            category.name,
            style: TextStyle(
              fontSize: 12,
              color: categoryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Converte cor hex para Color
  Color _hexToColor(String hexString) {
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return Colors.grey; // Fallback
    }
  }

  /// Converte nome do ícone para IconData
  IconData _getIconData(String? iconName) {
    if (iconName == null) return Icons.label;

    // Mapeamento de nomes de ícones comuns
    final iconMap = {
      'work': Icons.work,
      'home': Icons.home,
      'shopping_cart': Icons.shopping_cart,
      'school': Icons.school,
      'favorite': Icons.favorite,
      'star': Icons.star,
      'sports': Icons.sports_soccer,
      'restaurant': Icons.restaurant,
      'flight': Icons.flight,
      'directions_car': Icons.directions_car,
      'label': Icons.label,
    };

    return iconMap[iconName] ?? Icons.label;
  }
}
