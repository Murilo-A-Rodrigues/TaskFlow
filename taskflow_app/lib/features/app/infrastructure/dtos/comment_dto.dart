import 'dart:convert';

/// CommentDto - Data Transfer Object que espelha a tabela comments do Supabase
/// 
/// Esta classe representa os dados como eles são transferidos de e para
/// o Supabase/rede. Os nomes dos campos seguem snake_case (igual ao banco)
/// e os tipos são primitivos para facilitar serialização.
/// Segue o padrão DTO do documento "Modelo DTO e Mapeamento".
class CommentDto {
  final String id;
  final String content;
  final String task_id;            // FK para tasks table
  final String author_id;          // FK para users table
  final String? parent_id;         // FK para comments table (self-reference)
  final bool is_edited;           // snake_case igual ao banco
  final String? edited_at;         // ISO8601 String ou null
  final bool is_deleted;          // snake_case igual ao banco
  final String created_at;         // ISO8601 String para o fio
  final String updated_at;         // ISO8601 String para sincronização

  CommentDto({
    required this.id,
    required this.content,
    required this.task_id,
    required this.author_id,
    this.parent_id,
    required this.is_edited,
    this.edited_at,
    required this.is_deleted,
    required this.created_at,
    required this.updated_at,
  });

  /// Factory constructor para criar CommentDto a partir de Map (response do Supabase)
  factory CommentDto.fromMap(Map<String, dynamic> map) {
    return CommentDto(
      id: map['id'] as String,
      content: map['content'] as String,
      task_id: map['task_id'] as String,
      author_id: map['author_id'] as String,
      parent_id: map['parent_id'] as String?,
      is_edited: map['is_edited'] as bool,
      edited_at: map['edited_at'] as String?,
      is_deleted: map['is_deleted'] as bool,
      created_at: map['created_at'] as String,
      updated_at: map['updated_at'] as String,
    );
  }

  /// Converte CommentDto para Map (para enviar ao Supabase)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'task_id': task_id,
      'author_id': author_id,
      'parent_id': parent_id,
      'is_edited': is_edited,
      'edited_at': edited_at,
      'is_deleted': is_deleted,
      'created_at': created_at,
      'updated_at': updated_at,
    };
  }

  /// Factory constructor para criar CommentDto a partir de JSON string
  factory CommentDto.fromJson(String jsonString) {
    final Map<String, dynamic> map = json.decode(jsonString);
    return CommentDto.fromMap(map);
  }

  /// Converte CommentDto para JSON string (útil para cache)
  String toJson() {
    return json.encode(toMap());
  }

  /// Copy with para imutabilidade
  CommentDto copyWith({
    String? content,
    String? task_id,
    String? author_id,
    String? parent_id,
    bool? is_edited,
    String? edited_at,
    bool? is_deleted,
    String? updated_at,
  }) {
    return CommentDto(
      id: id,
      content: content ?? this.content,
      task_id: task_id ?? this.task_id,
      author_id: author_id ?? this.author_id,
      parent_id: parent_id ?? this.parent_id,
      is_edited: is_edited ?? this.is_edited,
      edited_at: edited_at ?? this.edited_at,
      is_deleted: is_deleted ?? this.is_deleted,
      created_at: created_at,
      updated_at: updated_at ?? this.updated_at,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CommentDto && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'CommentDto(id: $id, task_id: $task_id, author_id: $author_id, parent_id: $parent_id)';
  }
}
