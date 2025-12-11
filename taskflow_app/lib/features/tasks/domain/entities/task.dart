import 'task_priority.dart';

/// Task Entity - Modelo interno limpo e validado para uso no aplicativo
///
/// Esta é a representação "ideal" da tarefa dentro da aplicação.
/// Contém tipos fortes, validações e conveniências para a UI.
/// Segue o padrão Entity do documento "Modelo DTO e Mapeamento".
class Task {
  final String id;
  final String title;
  final String description;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? dueDate;
  final TaskPriority priority;
  final DateTime updatedAt;
  final String? categoryId;
  final String userId; // FK para User - tarefas são por usuário
  final bool isDeleted; // Soft delete flag
  final DateTime? deletedAt; // Timestamp de quando foi deletado

  Task({
    required this.id,
    required this.title,
    String? description,
    this.isCompleted = false,
    required this.createdAt,
    this.dueDate,
    TaskPriority? priority,
    required this.updatedAt,
    this.categoryId,
    required this.userId,
    this.isDeleted = false,
    this.deletedAt,
  }) : description = description?.trim() ?? '',
       priority = priority ?? TaskPriority.medium;

  /// Conveniência para a UI - texto formatado pronto para uso
  String get statusText => isCompleted ? 'Concluída' : 'Pendente';

  /// Conveniência para a UI - ícone baseado na prioridade
  String get priorityIcon {
    switch (priority) {
      case TaskPriority.low:
        return '🟢';
      case TaskPriority.medium:
        return '🟡';
      case TaskPriority.high:
        return '🔴';
    }
  }

  /// Conveniência para a UI - cor da prioridade
  String get priorityColorHex {
    switch (priority) {
      case TaskPriority.low:
        return '#10B981'; // Verde
      case TaskPriority.medium:
        return '#F59E0B'; // Amarelo
      case TaskPriority.high:
        return '#EF4444'; // Vermelho
    }
  }

  /// Conveniência para a UI - descrição formatada
  String get subtitle {
    final parts = <String>[];

    if (description.isNotEmpty && description.length > 30) {
      parts.add('${description.substring(0, 30)}...');
    } else if (description.isNotEmpty) {
      parts.add(description);
    }

    parts.add(priorityIcon);

    if (dueDate != null) {
      final now = DateTime.now();
      final difference = dueDate!.difference(now).inDays;

      if (difference < 0) {
        parts.add('Atrasada ${(-difference)} dia(s)');
      } else if (difference == 0) {
        parts.add('Vence hoje');
      } else if (difference == 1) {
        parts.add('Vence amanhã');
      } else {
        parts.add('Vence em $difference dias');
      }
    }

    return parts.join(' • ');
  }

  /// Indica se a tarefa está atrasada
  bool get isOverdue {
    if (dueDate == null || isCompleted) return false;
    return dueDate!.isBefore(DateTime.now());
  }

  /// Indica se a tarefa vence hoje
  bool get isDueToday {
    if (dueDate == null) return false;
    final now = DateTime.now();
    return dueDate!.year == now.year &&
        dueDate!.month == now.month &&
        dueDate!.day == now.day;
  }

  /// Cria uma cópia com valores opcionalmente modificados
  Task copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? dueDate,
    TaskPriority? priority,
    DateTime? updatedAt,
    String? categoryId,
    String? userId,
    bool? isDeleted,
    DateTime? deletedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      categoryId: categoryId ?? this.categoryId,
      userId: userId ?? this.userId,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Task &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.isCompleted == isCompleted &&
        other.createdAt == createdAt &&
        other.dueDate == dueDate &&
        other.priority == priority &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      description,
      isCompleted,
      createdAt,
      dueDate,
      priority,
      updatedAt,
    );
  }

  @override
  String toString() {
    return 'Task(id: $id, title: $title, isCompleted: $isCompleted, priority: $priority)';
  }
}
