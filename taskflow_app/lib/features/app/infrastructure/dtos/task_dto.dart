import 'dart:convert';

/// TaskDto - Data Transfer Object que espelha a tabela tasks do Supabase
/// 
/// Esta classe representa os dados como eles são transferidos de e para
/// o Supabase/rede. Os nomes dos campos seguem snake_case (igual ao banco)
/// e os tipos são primitivos para facilitar serialização.
/// Segue o padrão DTO do documento "Modelo DTO e Mapeamento".
class TaskDto {
  final String id;
  final String title;
  final String? description;
  final bool is_completed;        // snake_case igual ao banco
  final String created_at;        // ISO8601 String para o fio
  final String? due_date;         // ISO8601 String ou null
  final int priority;             // número para o banco
  final String updated_at;        // ISO8601 String para sincronização
  final String? category_id;      // FK para categories table

  TaskDto({
    required this.id,
    required this.title,
    this.description,
    required this.is_completed,
    required this.created_at,
    this.due_date,
    required this.priority,
    required this.updated_at,
    this.category_id,
  });

  /// Factory para criar TaskDto a partir de Map (vindo do Supabase)
  factory TaskDto.fromMap(Map<String, dynamic> map) {
    return TaskDto(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      is_completed: map['is_completed'] as bool,
      created_at: map['created_at'] as String,
      due_date: map['due_date'] as String?,
      priority: (map['priority'] as num).toInt(),
      updated_at: map['updated_at'] as String,
      category_id: map['category_id'] as String?,
    );
  }

  /// Converte TaskDto para Map (para enviar ao Supabase)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'is_completed': is_completed,
      'created_at': created_at,
      'due_date': due_date,
      'priority': priority,
      'updated_at': updated_at,
      'category_id': category_id,
    };
  }

  /// Factory para criar TaskDto a partir de JSON string
  factory TaskDto.fromJson(String jsonString) {
    final Map<String, dynamic> json = 
        Map<String, dynamic>.from(jsonDecode(jsonString));
    return TaskDto.fromMap(json);
  }

  /// Converte TaskDto para JSON string (para cache local)
  String toJson() {
    return jsonEncode(toMap());
  }

  /// Cria uma cópia com valores opcionalmente modificados
  TaskDto copyWith({
    String? id,
    String? title,
    String? description,
    bool? is_completed,
    String? created_at,
    String? due_date,
    int? priority,
    String? updated_at,
  }) {
    return TaskDto(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      is_completed: is_completed ?? this.is_completed,
      created_at: created_at ?? this.created_at,
      due_date: due_date ?? this.due_date,
      priority: priority ?? this.priority,
      updated_at: updated_at ?? this.updated_at,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TaskDto &&
           other.id == id &&
           other.title == title &&
           other.description == description &&
           other.is_completed == is_completed &&
           other.created_at == created_at &&
           other.due_date == due_date &&
           other.priority == priority &&
           other.updated_at == updated_at;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      description,
      is_completed,
      created_at,
      due_date,
      priority,
      updated_at,
    );
  }

  @override
  String toString() {
    return 'TaskDto(id: $id, title: $title, is_completed: $is_completed, priority: $priority)';
  }
}