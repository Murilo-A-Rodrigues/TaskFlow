import 'package:uuid/uuid.dart';
import 'project_status.dart';

/// Project Entity - Representação interna rica e validada do projeto
///
/// Esta classe representa um projeto no domínio da aplicação TaskFlow.
/// Contém tipos fortes, validações e invariantes de domínio.
/// Segue o padrão Entity do documento "Modelo DTO e Mapeamento".
class Project {
  final String id;
  final String name;
  final String description;
  final String ownerId; // FK para User
  final ProjectStatus status;
  final DateTime? startDate; // Nullable - pode ser definida depois
  final DateTime? endDate; // Nullable - pode ser definida depois
  final DateTime? deadline; // Nullable - prazo final
  final String? color; // Cor em hex para identificação visual
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  Project({
    String? id,
    required String name,
    String? description,
    required String ownerId,
    ProjectStatus? status,
    this.startDate,
    this.endDate,
    this.deadline,
    this.color,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       name = _validateName(name),
       description = description?.trim() ?? '',
       ownerId = _validateOwnerId(ownerId),
       status = status ?? ProjectStatus.planning,
       isArchived = isArchived ?? false,
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now() {
    _validateDates();
  }

  /// Validação de nome - deve ser não vazio e trimmed
  static String _validateName(String name) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Nome do projeto não pode ser vazio');
    }
    if (trimmedName.length < 2) {
      throw ArgumentError('Nome deve ter pelo menos 2 caracteres');
    }
    if (trimmedName.length > 100) {
      throw ArgumentError('Nome deve ter no máximo 100 caracteres');
    }
    return trimmedName;
  }

  /// Validação de owner ID
  static String _validateOwnerId(String ownerId) {
    if (ownerId.trim().isEmpty) {
      throw ArgumentError('ID do proprietário não pode ser vazio');
    }
    return ownerId.trim();
  }

  /// Validação de datas - invariantes de domínio
  void _validateDates() {
    // Start date deve ser anterior à end date
    if (startDate != null && endDate != null && startDate!.isAfter(endDate!)) {
      throw ArgumentError('Data de início deve ser anterior à data de fim');
    }

    // Deadline não pode ser no passado para projetos ativos
    if (deadline != null &&
        status.isActive &&
        deadline!.isBefore(DateTime.now())) {
      throw ArgumentError(
        'Prazo não pode estar no passado para projetos ativos',
      );
    }

    // End date não pode ser no futuro para projetos concluídos
    if (endDate != null &&
        status.isCompleted &&
        endDate!.isAfter(DateTime.now())) {
      throw ArgumentError(
        'Data de fim não pode estar no futuro para projetos concluídos',
      );
    }
  }

  /// Conveniências para a UI
  String get displayName => name;
  String get statusText => status.displayName;
  bool get hasDeadline => deadline != null;
  bool get isOverdue =>
      deadline != null &&
      deadline!.isBefore(DateTime.now()) &&
      !status.isCompleted;
  bool get hasDateRange => startDate != null && endDate != null;

  Duration? get duration {
    if (startDate == null || endDate == null) return null;
    return endDate!.difference(startDate!);
  }

  double get progress {
    if (!hasDateRange || status == ProjectStatus.planning) return 0.0;
    if (status.isCompleted) return 1.0;

    final now = DateTime.now();
    if (now.isBefore(startDate!)) return 0.0;
    if (now.isAfter(endDate!)) return 1.0;

    final totalDuration = endDate!.difference(startDate!).inDays;
    final elapsedDuration = now.difference(startDate!).inDays;

    return totalDuration > 0
        ? (elapsedDuration / totalDuration).clamp(0.0, 1.0)
        : 0.0;
  }

  /// Métodos de domínio
  Project start({DateTime? startDate}) {
    final newStartDate = startDate ?? DateTime.now();
    return copyWith(
      status: ProjectStatus.active,
      startDate: newStartDate,
      updatedAt: DateTime.now(),
    );
  }

  Project complete({DateTime? endDate}) {
    final newEndDate = endDate ?? DateTime.now();
    return copyWith(
      status: ProjectStatus.completed,
      endDate: newEndDate,
      updatedAt: DateTime.now(),
    );
  }

  Project pause() {
    if (!status.isActive) {
      throw StateError('Apenas projetos ativos podem ser pausados');
    }
    return copyWith(status: ProjectStatus.onHold, updatedAt: DateTime.now());
  }

  Project resume() {
    if (status != ProjectStatus.onHold) {
      throw StateError('Apenas projetos em pausa podem ser retomados');
    }
    return copyWith(status: ProjectStatus.active, updatedAt: DateTime.now());
  }

  Project cancel() {
    if (status.isCompleted || status.isCancelled) {
      throw StateError(
        'Projetos concluídos ou cancelados não podem ser cancelados novamente',
      );
    }
    return copyWith(status: ProjectStatus.cancelled, updatedAt: DateTime.now());
  }

  Project archive() {
    return copyWith(isArchived: true, updatedAt: DateTime.now());
  }

  Project unarchive() {
    return copyWith(isArchived: false, updatedAt: DateTime.now());
  }

  /// Copy with para imutabilidade
  Project copyWith({
    String? name,
    String? description,
    String? ownerId,
    ProjectStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? deadline,
    String? color,
    bool? isArchived,
    DateTime? updatedAt,
  }) {
    return Project(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      ownerId: ownerId ?? this.ownerId,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      deadline: deadline ?? this.deadline,
      color: color ?? this.color,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Project && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Project(id: $id, name: $name, status: ${status.value}, owner: $ownerId)';
  }
}
