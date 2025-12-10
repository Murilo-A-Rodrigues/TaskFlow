/// Reminder Entity - Modelo de lembrete de tarefa
///
/// Representa um lembrete agendado para uma tarefa específica
class Reminder {
  final String id;
  final String taskId;
  final DateTime reminderDate;
  final ReminderType type;
  final bool isActive;
  final DateTime createdAt;
  final String? customMessage;

  Reminder({
    required this.id,
    required this.taskId,
    required this.reminderDate,
    required this.type,
    this.isActive = true,
    required this.createdAt,
    this.customMessage,
  });

  Reminder copyWith({
    String? id,
    String? taskId,
    DateTime? reminderDate,
    ReminderType? type,
    bool? isActive,
    DateTime? createdAt,
    String? customMessage,
  }) {
    return Reminder(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      reminderDate: reminderDate ?? this.reminderDate,
      type: type ?? this.type,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      customMessage: customMessage ?? this.customMessage,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'task_id': taskId,
      'reminder_date': reminderDate.toIso8601String(),
      'type': type.name,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'custom_message': customMessage,
    };
  }

  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['id'] as String,
      taskId: map['task_id'] as String,
      reminderDate: DateTime.parse(map['reminder_date'] as String),
      type: ReminderType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => ReminderType.once,
      ),
      isActive: map['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
      customMessage: map['custom_message'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Reminder && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Tipos de lembrete
enum ReminderType {
  once, // Uma única vez
  daily, // Diariamente
  weekly, // Semanalmente
  monthly, // Mensalmente
}

extension ReminderTypeExtension on ReminderType {
  String get label {
    switch (this) {
      case ReminderType.once:
        return 'Uma vez';
      case ReminderType.daily:
        return 'Diariamente';
      case ReminderType.weekly:
        return 'Semanalmente';
      case ReminderType.monthly:
        return 'Mensalmente';
    }
  }
}
