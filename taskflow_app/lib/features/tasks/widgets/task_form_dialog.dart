import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/domain/entities/task.dart';
import '../../app/domain/entities/task_priority.dart';
import '../../../services/core/category_service.dart';
import '../../../services/core/reminder_service.dart';
import '../../app/domain/entities/reminder.dart';

/// Dialog reutilizável para criação e edição de tarefas
/// 
/// Implementa o Prompt 05 - Dialog parametrizável e validável.
/// Suporta múltiplos tipos de campo e validação em tempo real.
/// 
/// Uso:
/// ```dart
/// final result = await showTaskFormDialog(
///   context,
///   initial: existingTask, // null para criar nova
/// );
/// if (result != null) {
///   // Processar tarefa criada/editada
/// }
/// ```
class TaskFormDialog extends StatefulWidget {
  final Task? initialTask;

  const TaskFormDialog({
    super.key,
    this.initialTask,
  });

  @override
  State<TaskFormDialog> createState() => _TaskFormDialogState();
}

class _TaskFormDialogState extends State<TaskFormDialog> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers para campos de texto
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  
  // Estado dos campos
  TaskPriority _selectedPriority = TaskPriority.medium;
  DateTime? _selectedDueDate;
  String? _selectedCategoryId;
  DateTime? _selectedReminderDate;
  TimeOfDay? _selectedReminderTime;
  
  // Validação
  bool _titleHasError = false;

  @override
  void initState() {
    super.initState();
    
    // Inicializa controllers
    _titleController = TextEditingController(
      text: widget.initialTask?.title ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.initialTask?.description ?? '',
    );
    
    // Se estiver editando, preenche campos
    if (widget.initialTask != null) {
      _selectedPriority = widget.initialTask!.priority;
      _selectedDueDate = widget.initialTask!.dueDate;
      _selectedCategoryId = widget.initialTask!.categoryId;
      
      // Carrega lembrete existente (se houver)
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (mounted) {
          final reminderService = Provider.of<ReminderService>(context, listen: false);
          
          // Aguarda inicialização
          await reminderService.waitForInitialization();
          
          final reminders = reminderService.getRemindersForTask(widget.initialTask!.id);
          if (reminders.isNotEmpty) {
            final reminder = reminders.first;
            setState(() {
              _selectedReminderDate = reminder.reminderDate;
              _selectedReminderTime = TimeOfDay.fromDateTime(reminder.reminderDate);
            });
          }
        }
      });
    }
    
    // Listener para validação em tempo real
    _titleController.addListener(_validateTitle);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _validateTitle() {
    final hasError = _titleController.text.trim().isEmpty;
    if (hasError != _titleHasError) {
      setState(() {
        _titleHasError = hasError;
      });
    }
  }

  Future<void> _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Selecionar data de vencimento',
      cancelText: 'Cancelar',
      confirmText: 'OK',
    );
    
    if (date != null) {
      setState(() {
        _selectedDueDate = date;
      });
    }
  }

  void _submit() async {
    // Valida formulário
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Cria/atualiza tarefa
    final task = Task(
      id: widget.initialTask?.id ?? 
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      priority: _selectedPriority,
      dueDate: _selectedDueDate,
      categoryId: _selectedCategoryId,
      createdAt: widget.initialTask?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      isCompleted: widget.initialTask?.isCompleted ?? false,
    );

    // Gerenciar lembretes
    if (mounted) {
      final reminderService = Provider.of<ReminderService>(context, listen: false);
      
      // Aguarda inicialização do serviço
      await reminderService.waitForInitialization();
      
      final existingReminders = reminderService.getRemindersForTask(task.id);
      
      if (_selectedReminderDate != null) {
        // Validar se o horário não é passado
        if (_selectedReminderDate!.isBefore(DateTime.now())) {
          // Limpa o lembrete inválido primeiro
          setState(() {
            _selectedReminderDate = null;
            _selectedReminderTime = null;
          });
          
          // Mostra um AlertDialog em cima de TUDO (usa rootNavigator)
          if (mounted) {
            showDialog(
              context: context,
              useRootNavigator: true, // IMPORTANTE: Garante que aparece acima do dialog de tarefa
              barrierDismissible: false,
              builder: (dialogContext) => AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                    SizedBox(width: 12),
                    Text('Horário Inválido'),
                  ],
                ),
                content: const Text(
                  'Não é possível definir um lembrete para um horário que já passou.\n\n'
                  'Por favor, escolha um horário futuro.',
                  style: TextStyle(fontSize: 16),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('OK', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            );
          }
          
          return; // Não salva a tarefa se o lembrete for inválido
        }
        
        // Criar ou atualizar lembrete
        if (existingReminders.isNotEmpty) {
          // Atualiza o primeiro lembrete
          await reminderService.updateReminder(
            existingReminders.first.copyWith(
              reminderDate: _selectedReminderDate!,
            ),
            task,
          );
        } else {
          // Cria novo lembrete
          await reminderService.createReminder(
            task: task,
            reminderDate: _selectedReminderDate!,
            type: ReminderType.once,
          );
        }
      } else if (existingReminders.isNotEmpty) {
        // Se não tem lembrete selecionado mas tinha antes, remove todos
        for (final reminder in existingReminders) {
          await reminderService.deleteReminder(reminder.id);
        }
      }
    }

    // Retorna tarefa criada
    if (mounted) {
      Navigator.of(context).pop(task);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialTask != null;
    final theme = Theme.of(context);
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isEditing ? Icons.edit : Icons.add_task,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isEditing ? 'Editar Tarefa' : 'Nova Tarefa',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Fechar',
                  ),
                ],
              ),
            ),
            
            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Campo Título *
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Título *',
                          hintText: 'Ex: Fazer compras',
                          prefixIcon: const Icon(Icons.title),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.red, width: 2),
                          ),
                        ),
                        maxLength: 100,
                        autofocus: !isEditing, // Foco automático ao criar nova
                        textCapitalization: TextCapitalization.sentences,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor, insira um título';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Campo Descrição (opcional)
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Descrição (opcional)',
                          hintText: 'Adicione mais detalhes...',
                          prefixIcon: const Icon(Icons.description),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 3,
                        maxLength: 500,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: 16),
                      
                      // Campo Prioridade *
                      DropdownButtonFormField<TaskPriority>(
                        value: _selectedPriority,
                        decoration: InputDecoration(
                          labelText: 'Prioridade *',
                          prefixIcon: const Icon(Icons.flag),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: TaskPriority.values.map((priority) {
                          return DropdownMenuItem(
                            value: priority,
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: _getPriorityColor(priority),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(priority.displayName),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedPriority = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Campo Data de Vencimento (opcional)
                      InkWell(
                        onTap: _selectDueDate,
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Data de Vencimento (opcional)',
                            prefixIcon: const Icon(Icons.calendar_today),
                            suffixIcon: _selectedDueDate != null
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      setState(() {
                                        _selectedDueDate = null;
                                      });
                                    },
                                    tooltip: 'Remover data',
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _selectedDueDate != null
                                ? _formatDate(_selectedDueDate!)
                                : 'Selecionar data',
                            style: TextStyle(
                              color: _selectedDueDate != null
                                  ? theme.textTheme.bodyLarge?.color
                                  : theme.hintColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Campo Categoria (opcional)
                      _buildCategoryField(theme),
                      const SizedBox(height: 16),
                      
                      // Campo Lembrete (opcional)
                      _buildReminderField(theme),
                    ],
                  ),
                ),
              ),
            ),
            
            // Footer com botões
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: theme.dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(isEditing ? 'Salvar' : 'Adicionar'),
                  ),
                ],
              ),
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

  Widget _buildCategoryField(ThemeData theme) {
    final categoryService = Provider.of<CategoryService>(context, listen: false);
    final categories = categoryService.categories;
    
    return InkWell(
      onTap: () async {
        final selected = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Selecionar Categoria'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: const Text('Nenhuma categoria'),
                    leading: const Icon(Icons.cancel),
                    onTap: () => Navigator.pop(context, ''),
                  ),
                  ...categories.map((cat) => ListTile(
                    title: Text(cat.name),
                    leading: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Color(int.parse(cat.color.replaceAll('#', '0xff'))),
                        shape: BoxShape.circle,
                      ),
                    ),
                    onTap: () => Navigator.pop(context, cat.id),
                  )),
                ],
              ),
            ),
          ),
        );
        
        if (selected != null) {
          setState(() {
            _selectedCategoryId = selected.isEmpty ? null : selected;
          });
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Categoria (opcional)',
          prefixIcon: const Icon(Icons.category),
          suffixIcon: _selectedCategoryId != null
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _selectedCategoryId = null;
                    });
                  },
                  tooltip: 'Remover categoria',
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          _selectedCategoryId != null
              ? categories.firstWhere((c) => c.id == _selectedCategoryId).name
              : 'Selecionar categoria',
          style: TextStyle(
            color: _selectedCategoryId != null
                ? theme.textTheme.bodyLarge?.color
                : theme.hintColor,
          ),
        ),
      ),
    );
  }

  Widget _buildReminderField(ThemeData theme) {
    return InkWell(
      onTap: () async {
        // Mostrar date picker
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedReminderDate ?? _selectedDueDate ?? DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          helpText: 'Selecionar data do lembrete',
          cancelText: 'Cancelar',
          confirmText: 'OK',
        );
        
        if (date != null) {
          // Mostrar time picker customizado
          final time = await _showCustomTimePicker();
          
          if (time != null) {
            setState(() {
              _selectedReminderDate = DateTime(
                date.year,
                date.month,
                date.day,
                time.hour,
                time.minute,
              );
              _selectedReminderTime = time;
            });
          }
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Lembrete (opcional)',
          prefixIcon: const Icon(Icons.alarm),
          suffixIcon: _selectedReminderDate != null
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _selectedReminderDate = null;
                      _selectedReminderTime = null;
                    });
                  },
                  tooltip: 'Remover lembrete',
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          _selectedReminderDate != null
              ? '${_formatDate(_selectedReminderDate!)} às ${_selectedReminderTime!.format(context)}'
              : 'Selecionar lembrete',
          style: TextStyle(
            color: _selectedReminderDate != null
                ? theme.textTheme.bodyLarge?.color
                : theme.hintColor,
          ),
        ),
      ),
    );
  }

  Future<TimeOfDay?> _showCustomTimePicker() async {
    final initialTime = _selectedReminderTime ?? 
                       (_selectedDueDate != null 
                         ? TimeOfDay(hour: _selectedDueDate!.hour - 1, minute: 0)
                         : const TimeOfDay(hour: 9, minute: 0));
    
    return showDialog<TimeOfDay>(
      context: context,
      builder: (context) => _CustomTimePickerDialog(initialTime: initialTime),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    if (dateOnly == today) {
      return 'Hoje';
    } else if (dateOnly == tomorrow) {
      return 'Amanhã';
    } else {
      return '${date.day.toString().padLeft(2, '0')}/'
             '${date.month.toString().padLeft(2, '0')}/'
             '${date.year}';
    }
  }
}

/// Widget customizado para seleção de hora com scroll
class _CustomTimePickerDialog extends StatefulWidget {
  final TimeOfDay initialTime;

  const _CustomTimePickerDialog({required this.initialTime});

  @override
  State<_CustomTimePickerDialog> createState() => _CustomTimePickerDialogState();
}

class _CustomTimePickerDialogState extends State<_CustomTimePickerDialog> {
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;
  late int _selectedHour;
  late int _selectedMinute;

  @override
  void initState() {
    super.initState();
    _selectedHour = widget.initialTime.hour;
    _selectedMinute = widget.initialTime.minute;
    _hourController = FixedExtentScrollController(initialItem: _selectedHour);
    _minuteController = FixedExtentScrollController(initialItem: _selectedMinute);
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: const Text('Selecionar Horário'),
      content: SizedBox(
        height: 200,
        width: 200,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Hora
            Expanded(
              child: Column(
                children: [
                  Text('Hora', style: theme.textTheme.labelSmall),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListWheelScrollView.useDelegate(
                      controller: _hourController,
                      itemExtent: 50,
                      perspective: 0.005,
                      diameterRatio: 1.2,
                      physics: const FixedExtentScrollPhysics(),
                      onSelectedItemChanged: (index) {
                        setState(() {
                          _selectedHour = index;
                        });
                      },
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: 24,
                        builder: (context, index) {
                          final isSelected = index == _selectedHour;
                          return Center(
                            child: Text(
                              index.toString().padLeft(2, '0'),
                              style: TextStyle(
                                fontSize: isSelected ? 32 : 24,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? theme.primaryColor : theme.textTheme.bodyLarge?.color?.withOpacity(0.5),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(':', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            ),
            // Minuto
            Expanded(
              child: Column(
                children: [
                  Text('Minuto', style: theme.textTheme.labelSmall),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListWheelScrollView.useDelegate(
                      controller: _minuteController,
                      itemExtent: 50,
                      perspective: 0.005,
                      diameterRatio: 1.2,
                      physics: const FixedExtentScrollPhysics(),
                      onSelectedItemChanged: (index) {
                        setState(() {
                          _selectedMinute = index;
                        });
                      },
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: 60,
                        builder: (context, index) {
                          final isSelected = index == _selectedMinute;
                          return Center(
                            child: Text(
                              index.toString().padLeft(2, '0'),
                              style: TextStyle(
                                fontSize: isSelected ? 32 : 24,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? theme.primaryColor : theme.textTheme.bodyLarge?.color?.withOpacity(0.5),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, TimeOfDay(hour: _selectedHour, minute: _selectedMinute));
          },
          child: const Text('OK'),
        ),
      ],
    );
  }
}

/// Função helper para mostrar o dialog
/// 
/// Retorna a tarefa criada/editada ou null se cancelado
Future<Task?> showTaskFormDialog(
  BuildContext context, {
  Task? initial,
}) {
  return showDialog<Task>(
    context: context,
    barrierDismissible: false,
    builder: (context) => TaskFormDialog(initialTask: initial),
  );
}
