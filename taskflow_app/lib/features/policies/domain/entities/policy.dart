/// Policy Entity - Representa uma política no domínio da aplicação
class Policy {
  final String id;
  final String name;
  final String description;
  final String content;
  final String version;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? effectiveDate;

  const Policy({
    required this.id,
    required this.name,
    required this.description,
    required this.content,
    required this.version,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
    this.effectiveDate,
  });

  Policy copyWith({
    String? id,
    String? name,
    String? description,
    String? content,
    String? version,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? effectiveDate,
  }) {
    return Policy(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      content: content ?? this.content,
      version: version ?? this.version,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      effectiveDate: effectiveDate ?? this.effectiveDate,
    );
  }

  @override
  String toString() {
    return 'Policy(id: $id, name: $name, version: $version, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Policy && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
