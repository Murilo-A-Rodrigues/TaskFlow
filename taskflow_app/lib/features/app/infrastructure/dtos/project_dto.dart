import 'dart:convert';

/// ProjectDto - Data Transfer Object que espelha a tabela projects do Supabase
/// 
/// Esta classe representa os dados como eles são transferidos de e para
/// o Supabase/rede. Os nomes dos campos seguem snake_case (igual ao banco)
/// e os tipos são primitivos para facilitar serialização.
/// Segue o padrão DTO do documento "Modelo DTO e Mapeamento".
class ProjectDto {
  final String id;
  final String name;
  final String? description;
  final String owner_id;           // FK para users table
  final String status;             // String para o banco
  final String? start_date;        // ISO8601 String ou null
  final String? end_date;          // ISO8601 String ou null
  final String? deadline;          // ISO8601 String ou null
  final String? color;             // Cor em hex
  final bool is_archived;          // snake_case igual ao banco
  final String created_at;         // ISO8601 String para o fio
  final String updated_at;         // ISO8601 String para sincronização

  ProjectDto({
    required this.id,
    required this.name,
    this.description,
    required this.owner_id,
    required this.status,
    this.start_date,
    this.end_date,
    this.deadline,
    this.color,
    required this.is_archived,
    required this.created_at,
    required this.updated_at,
  });

  /// Factory constructor para criar ProjectDto a partir de Map (response do Supabase)
  factory ProjectDto.fromMap(Map<String, dynamic> map) {
    return ProjectDto(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      owner_id: map['owner_id'] as String,
      status: map['status'] as String,
      start_date: map['start_date'] as String?,
      end_date: map['end_date'] as String?,
      deadline: map['deadline'] as String?,
      color: map['color'] as String?,
      is_archived: map['is_archived'] as bool,
      created_at: map['created_at'] as String,
      updated_at: map['updated_at'] as String,
    );
  }

  /// Converte ProjectDto para Map (para enviar ao Supabase)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'owner_id': owner_id,
      'status': status,
      'start_date': start_date,
      'end_date': end_date,
      'deadline': deadline,
      'color': color,
      'is_archived': is_archived,
      'created_at': created_at,
      'updated_at': updated_at,
    };
  }

  /// Factory constructor para criar ProjectDto a partir de JSON string
  factory ProjectDto.fromJson(String jsonString) {
    final Map<String, dynamic> map = json.decode(jsonString);
    return ProjectDto.fromMap(map);
  }

  /// Converte ProjectDto para JSON string (útil para cache)
  String toJson() {
    return json.encode(toMap());
  }

  /// Copy with para imutabilidade
  ProjectDto copyWith({
    String? name,
    String? description,
    String? owner_id,
    String? status,
    String? start_date,
    String? end_date,
    String? deadline,
    String? color,
    bool? is_archived,
    String? updated_at,
  }) {
    return ProjectDto(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      owner_id: owner_id ?? this.owner_id,
      status: status ?? this.status,
      start_date: start_date ?? this.start_date,
      end_date: end_date ?? this.end_date,
      deadline: deadline ?? this.deadline,
      color: color ?? this.color,
      is_archived: is_archived ?? this.is_archived,
      created_at: created_at,
      updated_at: updated_at ?? this.updated_at,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProjectDto && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ProjectDto(id: $id, name: $name, status: $status, owner_id: $owner_id)';
  }
}