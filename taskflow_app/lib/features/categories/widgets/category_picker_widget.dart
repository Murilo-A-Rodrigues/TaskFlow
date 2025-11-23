import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../categories/application/category_service.dart';
import '../../../features/app/domain/entities/category.dart';

/// CategoryPickerWidget - Widget para selecionar categoria
/// 
/// Usado no formulário de tarefas para associar uma categoria.
/// Exibe lista de categorias em um bottom sheet.
class CategoryPickerWidget extends StatelessWidget {
  final String? selectedCategoryId;
  final ValueChanged<Category?> onCategorySelected;

  const CategoryPickerWidget({
    super.key,
    this.selectedCategoryId,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<CategoryService>(
      builder: (context, categoryService, child) {
        final selectedCategory = selectedCategoryId != null
            ? categoryService.getCategoryById(selectedCategoryId!)
            : null;

        return InkWell(
          onTap: () => _showCategoryPicker(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.category_outlined,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Categoria',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                      const SizedBox(height: 4),
                      selectedCategory != null
                          ? Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: _parseColor(selectedCategory.color),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  selectedCategory.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              'Selecione uma categoria',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCategoryPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CategoryPickerSheet(
        selectedCategoryId: selectedCategoryId,
        onCategorySelected: onCategorySelected,
      ),
    );
  }

  /// Parse da cor hexadecimal para Color
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

/// Bottom sheet para seleção de categoria
class _CategoryPickerSheet extends StatelessWidget {
  final String? selectedCategoryId;
  final ValueChanged<Category?> onCategorySelected;

  const _CategoryPickerSheet({
    this.selectedCategoryId,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
                Text(
                  'Selecionar Categoria',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                if (selectedCategoryId != null)
                  TextButton(
                    onPressed: () {
                      onCategorySelected(null);
                      Navigator.pop(context);
                    },
                    child: const Text('Remover'),
                  ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Lista de categorias
          Flexible(
            child: Consumer<CategoryService>(
              builder: (context, categoryService, child) {
                final categories = categoryService.rootCategories;

                if (categories.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.category_outlined,
                            size: 64,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Nenhuma categoria disponível',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = category.id == selectedCategoryId;

                    return _CategoryOption(
                      category: category,
                      isSelected: isSelected,
                      onTap: () {
                        onCategorySelected(category);
                        Navigator.pop(context);
                      },
                    );
                  },
                );
              },
            ),
          ),

          // Padding bottom para safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}

/// Widget de opção de categoria na lista
class _CategoryOption extends StatelessWidget {
  final Category category;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryOption({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final categoryColor = _parseColor(category.color);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isSelected
          ? categoryColor.withOpacity(0.1)
          : null,
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: categoryColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _parseIcon(category.icon),
            color: categoryColor,
            size: 20,
          ),
        ),
        title: Text(
          category.name,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        subtitle: category.description != null
            ? Text(
                category.description!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: isSelected
            ? Icon(
                Icons.check_circle,
                color: categoryColor,
              )
            : null,
      ),
    );
  }

  /// Parse da cor hexadecimal para Color
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

  /// Parse do nome do ícone para IconData
  IconData _parseIcon(String? iconName) {
    if (iconName == null || iconName.isEmpty) {
      return Icons.category;
    }

    switch (iconName.toLowerCase()) {
      case 'work':
        return Icons.work;
      case 'person':
      case 'personal':
        return Icons.person;
      case 'school':
      case 'study':
        return Icons.school;
      case 'favorite':
      case 'health':
        return Icons.favorite;
      case 'home':
        return Icons.home;
      case 'shopping':
        return Icons.shopping_cart;
      case 'sports':
        return Icons.sports_soccer;
      case 'restaurant':
      case 'food':
        return Icons.restaurant;
      case 'local_activity':
      case 'entertainment':
        return Icons.local_activity;
      default:
        return Icons.category;
    }
  }
}
