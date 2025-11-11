import 'package:flutter/material.dart';
import '../../app/domain/entities/task.dart';
import '../../app/domain/entities/task_priority.dart';

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

  void _submit() {
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
      createdAt: widget.initialTask?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      isCompleted: widget.initialTask?.isCompleted ?? false,
    );

    // Retorna tarefa criada
    Navigator.of(context).pop(task);
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
