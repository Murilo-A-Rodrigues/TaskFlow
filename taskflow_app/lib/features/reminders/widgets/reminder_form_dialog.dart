import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/core/reminder_service.dart';
import '../../../features/app/domain/entities/reminder.dart';
import '../../../features/app/domain/entities/task.dart';

/// ReminderFormDialog - Diálogo para criar/editar lembretes
/// 
/// Permite configurar:
/// - Data e hora do lembrete
/// - Tipo (uma vez, diário, semanal, mensal)
/// - Mensagem personalizada
class ReminderFormDialog extends StatefulWidget {
  final Task task;
  final Reminder? reminder;

  const ReminderFormDialog({
    super.key,
    required this.task,
    this.reminder,
  });

  @override
  State<ReminderFormDialog> createState() => _ReminderFormDialogState();
}

class _ReminderFormDialogState extends State<ReminderFormDialog> {
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late ReminderType _selectedType;
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    if (widget.reminder != null) {
      _selectedDate = widget.reminder!.reminderDate;
      _selectedTime = TimeOfDay.fromDateTime(widget.reminder!.reminderDate);
      _selectedType = widget.reminder!.type;
      _messageController.text = widget.reminder!.customMessage ?? '';
    } else {
      // Define data/hora padrão para 1 hora antes do prazo da tarefa
      if (widget.task.dueDate != null) {
        _selectedDate = widget.task.dueDate!.subtract(const Duration(hours: 1));
        _selectedTime = TimeOfDay.fromDateTime(_selectedDate);
      } else {
        // Ou amanhã às 9h se não houver prazo
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        _selectedDate = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9, 0);
        _selectedTime = const TimeOfDay(hour: 9, minute: 0);
      }
      _selectedType = ReminderType.once;
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.reminder != null;

    return AlertDialog(
      title: Text(isEditing ? 'Editar Lembrete' : 'Novo Lembrete'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info da tarefa
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.task_alt,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.task.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Seleção de data
            Text(
              'Data e Hora',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(_formatDate(_selectedDate)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.access_time, size: 18),
                    label: Text(_formatTime(_selectedTime)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Tipo de lembrete
            Text(
              'Repetir',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ReminderType.values.map((type) {
                return ChoiceChip(
                  label: Text(type.label),
                  selected: _selectedType == type,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedType = type;
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Mensagem personalizada
            Text(
              'Mensagem Personalizada (opcional)',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Ex: Lembrete: Reunião importante',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.message),
                helperText: 'Deixe vazio para usar o título da tarefa',
              ),
              maxLength: 100,
            ),
          ],
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  Future<void> _handleSubmit() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final reminderService = context.read<ReminderService>();
      final customMessage = _messageController.text.trim().isEmpty
          ? null
          : _messageController.text.trim();

      if (widget.reminder != null) {
        // Atualiza lembrete existente
        final updated = widget.reminder!.copyWith(
          reminderDate: _selectedDate,
          type: _selectedType,
          customMessage: customMessage,
        );
        await reminderService.updateReminder(updated, widget.task);
      } else {
        // Cria novo lembrete
        await reminderService.createReminder(
          task: widget.task,
          reminderDate: _selectedDate,
          type: _selectedType,
          customMessage: customMessage,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.reminder != null
                  ? 'Lembrete atualizado com sucesso'
                  : 'Lembrete criado com sucesso',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar lembrete: $e'),
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

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
