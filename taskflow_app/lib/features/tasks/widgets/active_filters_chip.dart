import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/core/task_filter_service.dart';
import '../../categories/application/category_service.dart';
import '../../../features/app/domain/entities/task_priority.dart';

/// ActiveFiltersChip - Widget que exibe os filtros ativos como chips removíveis
/// 
/// Mostra chips para cada tipo de filtro ativo e permite removê-los individualmente
class ActiveFiltersChip extends StatelessWidget {
  const ActiveFiltersChip({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<TaskFilterService, CategoryService>(
      builder: (context, filterService, categoryService, child) {
        if (!filterService.hasActiveFilters) {
          return const SizedBox.shrink();
        }

        final chips = <Widget>[];

        // Chips de categoria
        for (final categoryId in filterService.selectedCategoryIds) {
          final category = categoryService.getCategoryById(categoryId);
          if (category != null) {
            chips.add(
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Chip(
                  avatar: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: _parseColor(category.color),
                      shape: BoxShape.circle,
                    ),
                  ),
                  label: Text(
                    category.name,
                    style: const TextStyle(fontSize: 12),
                  ),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () {
                    filterService.toggleCategory(categoryId);
                  },
                  visualDensity: VisualDensity.compact,
                ),
              ),
            );
          }
        }

        // Chips de prioridade
        for (final priority in filterService.selectedPriorities) {
          chips.add(
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                avatar: Icon(
                  _getPriorityIcon(priority),
                  size: 16,
                  color: _getPriorityColor(priority),
                ),
                label: Text(
                  _getPriorityLabel(priority),
                  style: const TextStyle(fontSize: 12),
                ),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () {
                  filterService.togglePriority(priority);
                },
                visualDensity: VisualDensity.compact,
              ),
            ),
          );
        }

        // Chip de status
        if (filterService.statusFilter != TaskStatusFilter.all) {
          chips.add(
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                avatar: const Icon(Icons.check_circle_outline, size: 16),
                label: Text(
                  filterService.statusFilter.label,
                  style: const TextStyle(fontSize: 12),
                ),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () {
                  filterService.removeFilter(FilterType.status);
                },
                visualDensity: VisualDensity.compact,
              ),
            ),
          );
        }

        // Chip de intervalo de datas
        if (filterService.dateRangeFilter != DateRangeFilter.all) {
          chips.add(
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                avatar: const Icon(Icons.calendar_today, size: 16),
                label: Text(
                  filterService.dateRangeFilter.label,
                  style: const TextStyle(fontSize: 12),
                ),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () {
                  filterService.removeFilter(FilterType.dateRange);
                },
                visualDensity: VisualDensity.compact,
              ),
            ),
          );
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...chips,
                if (filterService.activeFiltersCount > 1)
                  TextButton.icon(
                    onPressed: () {
                      filterService.clearAllFilters();
                    },
                    icon: const Icon(Icons.clear_all, size: 16),
                    label: const Text(
                      'Limpar Tudo',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _parseColor(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) {
      return Colors.blue;
    }
    try {
      final hex = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return Colors.blue;
    }
  }

  String _getPriorityLabel(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return 'Baixa';
      case TaskPriority.medium:
        return 'Média';
      case TaskPriority.high:
        return 'Alta';
    }
  }

  IconData _getPriorityIcon(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return Icons.arrow_downward;
      case TaskPriority.medium:
        return Icons.remove;
      case TaskPriority.high:
        return Icons.arrow_upward;
    }
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
}
