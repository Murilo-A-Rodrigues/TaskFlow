/// ProjectStatus - Enum para status válidos de um projeto
enum ProjectStatus {
  planning('planning', 'Planejamento'),
  active('active', 'Em Andamento'),
  onHold('on_hold', 'Em Pausa'),
  completed('completed', 'Concluído'),
  cancelled('cancelled', 'Cancelado');

  const ProjectStatus(this.value, this.displayName);

  final String value;
  final String displayName;

  /// Helper para converter string do banco para enum
  static ProjectStatus fromValue(String value) {
    return ProjectStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => ProjectStatus.planning,
    );
  }

  /// Helper para validar se um status é ativo
  bool get isActive => this == ProjectStatus.active;
  bool get isCompleted => this == ProjectStatus.completed;
  bool get isCancelled => this == ProjectStatus.cancelled;
}
