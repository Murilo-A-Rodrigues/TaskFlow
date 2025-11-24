import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../application/task_filter_service.dart';
import '../../categories/application/category_service.dart';
import '../domain/entities/task_priority.dart';

/// FilterBottomSheet - Bottom sheet para configurar filtros de tarefas
/// 
/// Permite ao usuário filtrar tarefas por:
/// - Categoria (múltipla seleção)
/// - Prioridade (múltipla seleção)
/// - Status (Todas/Pendentes/Concluídas/Atrasadas)
/// - Intervalo de datas (Hoje/Semana/Mês/Personalizado)
class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.filter_list,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Filtrar Tarefas',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                Consumer<TaskFilterService>(
                  builder: (context, filterService, child) {
                    if (!filterService.hasActiveFilters) {
                      return const SizedBox.shrink();
                    }
                    return TextButton(
                      onPressed: () {
                        filterService.clearAllFilters();
                      },
                      child: const Text('Limpar Tudo'),
                    );
                  },
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Filtros
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filtro por Categoria
                  _buildSectionTitle('Categoria'),
                  const SizedBox(height: 12),
                  const _CategoryFilter(),
                  const SizedBox(height: 24),

                  // Filtro por Prioridade
                  _buildSectionTitle('Prioridade'),
                  const SizedBox(height: 12),
                  const _PriorityFilter(),
                  const SizedBox(height: 24),

                  // Filtro por Status
                  _buildSectionTitle('Status'),
                  const SizedBox(height: 12),
                  const _StatusFilter(),
                  const SizedBox(height: 24),

                  // Filtro por Data
                  _buildSectionTitle('Data de Vencimento'),
                  const SizedBox(height: 12),
                  const _DateRangeFilter(),
                ],
              ),
            ),
          ),

          // Botão Aplicar
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              MediaQuery.of(context).padding.bottom + 16,
            ),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Aplicar Filtros'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

/// Widget de filtro por categoria
class _CategoryFilter extends StatelessWidget {
  const _CategoryFilter();

  @override
  Widget build(BuildContext context) {
    return Consumer2<CategoryService, TaskFilterService>(
      builder: (context, categoryService, filterService, child) {
        final categories = categoryService.rootCategories;

        if (categories.isEmpty) {
          return Text(
            'Nenhuma categoria disponível',
            style: TextStyle(
              color: Theme.of(context).colorScheme.outline,
            ),
          );
        }

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categories.map((category) {
            final isSelected = filterService.selectedCategoryIds.contains(category.id);
            final categoryColor = _parseColor(category.color);

            return FilterChip(
              label: Text(category.name),
              selected: isSelected,
              onSelected: (_) {
                filterService.toggleCategory(category.id);
              },
              avatar: isSelected
                  ? null
                  : Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: categoryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
              selectedColor: categoryColor.withOpacity(0.2),
              checkmarkColor: categoryColor,
            );
          }).toList(),
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
}

/// Widget de filtro por prioridade
class _PriorityFilter extends StatelessWidget {
  const _PriorityFilter();

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskFilterService>(
      builder: (context, filterService, child) {
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: TaskPriority.values.map((priority) {
            final isSelected = filterService.selectedPriorities.contains(priority);
            
            return FilterChip(
              label: Text(_getPriorityLabel(priority)),
              selected: isSelected,
              onSelected: (_) {
                filterService.togglePriority(priority);
              },
              avatar: isSelected
                  ? null
                  : Icon(
                      _getPriorityIcon(priority),
                      size: 16,
                      color: _getPriorityColor(priority),
                    ),
              selectedColor: _getPriorityColor(priority).withOpacity(0.2),
              checkmarkColor: _getPriorityColor(priority),
            );
          }).toList(),
        );
      },
    );
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

/// Widget de filtro por status
class _StatusFilter extends StatelessWidget {
  const _StatusFilter();

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskFilterService>(
      builder: (context, filterService, child) {
        return Column(
          children: TaskStatusFilter.values.map((status) {
            return RadioListTile<TaskStatusFilter>(
              title: Text(status.label),
              value: status,
              groupValue: filterService.statusFilter,
              onChanged: (value) {
                if (value != null) {
                  filterService.setStatusFilter(value);
                }
              },
              dense: true,
              contentPadding: EdgeInsets.zero,
            );
          }).toList(),
        );
      },
    );
  }
}

/// Widget de filtro por intervalo de datas
class _DateRangeFilter extends StatelessWidget {
  const _DateRangeFilter();

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskFilterService>(
      builder: (context, filterService, child) {
        return Column(
          children: [
            ...DateRangeFilter.values.where((f) => f != DateRangeFilter.custom).map((range) {
              return RadioListTile<DateRangeFilter>(
                title: Text(range.label),
                value: range,
                groupValue: filterService.dateRangeFilter,
                onChanged: (value) {
                  if (value != null) {
                    filterService.setDateRangeFilter(value);
                  }
                },
                dense: true,
                contentPadding: EdgeInsets.zero,
              );
            }),
            
            // Opção personalizada
            RadioListTile<DateRangeFilter>(
              title: const Text('Personalizado'),
              subtitle: filterService.dateRangeFilter == DateRangeFilter.custom &&
                      filterService.customStartDate != null &&
                      filterService.customEndDate != null
                  ? Text(
                      '${_formatDate(filterService.customStartDate!)} - ${_formatDate(filterService.customEndDate!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    )
                  : null,
              value: DateRangeFilter.custom,
              groupValue: filterService.dateRangeFilter,
              onChanged: (value) async {
                if (value != null) {
                  final result = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context),
                        child: child!,
                      );
                    },
                  );

                  if (result != null) {
                    filterService.setDateRangeFilter(
                      DateRangeFilter.custom,
                      start: result.start,
                      end: result.end,
                    );
                  }
                }
              },
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
