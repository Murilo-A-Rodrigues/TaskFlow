import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../services/core/supabase_service.dart';
import '../../categories/application/category_service.dart';
import '../../../features/app/domain/entities/category.dart';

/// CategoryFormDialog - Diálogo para criar/editar categorias
///
/// Permite configurar:
/// - Nome da categoria
/// - Descrição (opcional)
/// - Cor
/// - Ícone
class CategoryFormDialog extends StatefulWidget {
  final Category? category;

  const CategoryFormDialog({super.key, this.category});

  @override
  State<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;

  late String _selectedColor;
  late String _selectedIcon;
  bool _isLoading = false;

  // Cores disponíveis (formato hexadecimal)
  static const _availableColors = [
    '#2196F3', // Blue
    '#4CAF50', // Green
    '#FF9800', // Orange
    '#F44336', // Red
    '#9C27B0', // Purple
    '#00BCD4', // Cyan
    '#FFEB3B', // Yellow
    '#795548', // Brown
    '#607D8B', // Blue Grey
    '#E91E63', // Pink
  ];

  // Ícones disponíveis
  static const _availableIcons = [
    {'name': 'work', 'icon': Icons.work},
    {'name': 'person', 'icon': Icons.person},
    {'name': 'school', 'icon': Icons.school},
    {'name': 'favorite', 'icon': Icons.favorite},
    {'name': 'home', 'icon': Icons.home},
    {'name': 'shopping', 'icon': Icons.shopping_cart},
    {'name': 'sports', 'icon': Icons.sports_soccer},
    {'name': 'restaurant', 'icon': Icons.restaurant},
    {'name': 'local_activity', 'icon': Icons.local_activity},
    {'name': 'category', 'icon': Icons.category},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _descriptionController = TextEditingController(
      text: widget.category?.description ?? '',
    );
    _selectedColor = widget.category?.color ?? _availableColors[0];
    _selectedIcon = widget.category?.icon ?? 'category';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.category != null;

    return AlertDialog(
      title: Text(isEditing ? 'Editar Categoria' : 'Nova Categoria'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Campo de nome
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome *',
                  hintText: 'Ex: Trabalho, Pessoal...',
                  prefixIcon: Icon(Icons.label),
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Digite um nome para a categoria';
                  }
                  if (value.trim().length < 2) {
                    return 'Nome deve ter pelo menos 2 caracteres';
                  }
                  if (value.trim().length > 50) {
                    return 'Nome deve ter no máximo 50 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Campo de descrição
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descrição (opcional)',
                  hintText: 'Descreva esta categoria...',
                  prefixIcon: Icon(Icons.notes),
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                maxLength: 200,
              ),
              const SizedBox(height: 16),

              // Seleção de cor
              Text(
                'Cor',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableColors.map((colorHex) {
                  return _ColorOption(
                    color: _parseColor(colorHex),
                    isSelected: _selectedColor == colorHex,
                    onTap: () {
                      setState(() {
                        _selectedColor = colorHex;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Seleção de ícone
              Text(
                'Ícone',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableIcons.map((iconData) {
                  return _IconOption(
                    icon: iconData['icon'] as IconData,
                    isSelected: _selectedIcon == iconData['name'],
                    color: _parseColor(_selectedColor),
                    onTap: () {
                      setState(() {
                        _selectedIcon = iconData['name'] as String;
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _handleSubmit,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEditing ? 'Salvar' : 'Criar'),
        ),
      ],
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final categoryService = context.read<CategoryService>();

      // Verificar se já existe categoria com mesma cor e ícone
      final isDuplicate = categoryService.categories.any((cat) {
        return cat.id != widget.category?.id &&
            cat.color == _selectedColor &&
            cat.icon == _selectedIcon;
      });

      if (isDuplicate) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          
          // Mostra AlertDialog para mensagem de erro
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Combinação Duplicada',
                      overflow: TextOverflow.visible,
                    ),
                  ),
                ],
              ),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: const Text(
                  'Já existe uma categoria com esta cor e ícone.\n\nPor favor, escolha uma combinação diferente.',
                  style: TextStyle(fontSize: 15),
                ),
              ),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Entendi'),
                ),
              ],
            ),
          );
        }
        return;
      }

      final category = Category(
        id: widget.category?.id ?? const Uuid().v4(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        color: _selectedColor,
        icon: _selectedIcon,
        userId: SupabaseService.currentUserId ?? '00000000-0000-0000-0000-000000000000',
        createdAt: widget.category?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.category != null) {
        await categoryService.updateCategory(category);
      } else {
        await categoryService.addCategory(category);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.category != null
                  ? 'Categoria atualizada com sucesso'
                  : 'Categoria criada com sucesso',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar categoria: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Parse da cor hexadecimal para Color
  Color _parseColor(String hexColor) {
    try {
      final hex = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return Colors.blue;
    }
  }
}

/// Widget de opção de cor
class _ColorOption extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorOption({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 3,
                )
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
      ),
    );
  }
}

/// Widget de opção de ícone
class _IconOption extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _IconOption({
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Theme.of(context).colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Icon(
          icon,
          color: isSelected ? color : Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}
