import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../categories/application/category_service.dart';
import '../../../features/app/domain/entities/category.dart';
import '../widgets/category_form_dialog.dart';

/// CategoryManagementPage - Tela de gerenciamento de categorias
/// 
/// Permite ao usuário:
/// - Visualizar todas as categorias
/// - Adicionar novas categorias
/// - Editar categorias existentes
/// - Excluir categorias
class CategoryManagementPage extends StatelessWidget {
  const CategoryManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Categorias'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
      body: Consumer<CategoryService>(
        builder: (context, categoryService, child) {
          final categories = categoryService.rootCategories;

          if (categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.category_outlined,
                    size: 80,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhuma categoria encontrada',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Adicione sua primeira categoria',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return _CategoryCard(
                category: category,
                onEdit: () => _showEditDialog(context, category),
                onDelete: () => _confirmDelete(context, category),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Nova Categoria'),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const CategoryFormDialog(),
    );
  }

  void _showEditDialog(BuildContext context, Category category) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CategoryFormDialog(category: category),
    );
  }

  void _confirmDelete(BuildContext context, Category category) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Categoria'),
        content: Text(
          'Tem certeza que deseja excluir a categoria "${category.name}"?\n\n'
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
              try {
                await context.read<CategoryService>().deleteCategory(category.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Categoria excluída com sucesso'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro ao excluir categoria: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
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
  }
}

/// Widget de card para exibir uma categoria
class _CategoryCard extends StatelessWidget {
  final Category category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryCard({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // Parse da cor hexadecimal
    Color categoryColor = _parseColor(category.color);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: categoryColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _parseIcon(category.icon),
            color: categoryColor,
          ),
        ),
        title: Text(
          category.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: category.description != null
            ? Text(
                category.description!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: onEdit,
              tooltip: 'Editar',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
              tooltip: 'Excluir',
              color: Colors.red,
            ),
          ],
        ),
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
