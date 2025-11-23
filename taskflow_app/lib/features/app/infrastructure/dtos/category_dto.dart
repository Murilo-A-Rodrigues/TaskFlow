import 'dart:convert';

/// CategoryDto - Data Transfer Object que espelha a tabela categories do Supabase
/// 
/// Esta classe representa os dados como eles são transferidos de e para
/// o Supabase/rede. Os nomes dos campos seguem snake_case (igual ao banco)
/// e os tipos são primitivos para facilitar serialização.
/// Segue o padrão DTO do documento "Modelo DTO e Mapeamento".
class CategoryDto {
  final String id;
  final String name;
  final String? description;
  final String user_id;            // FK para users table
  final String? parent_id;         // FK para categories table (self-reference)
  final String color;              // Cor em hex
  final String? icon;              // Nome do ícone
  final int sort_order;            // Ordem de exibição
  final bool is_active;            // snake_case igual ao banco
  final String created_at;         // ISO8601 String para o fio
  final String updated_at;         // ISO8601 String para sincronização

  CategoryDto({
    required this.id,
    required this.name,
    this.description,
    required this.user_id,
    this.parent_id,
    required this.color,
    this.icon,
    required this.sort_order,
    required this.is_active,
    required this.created_at,
    required this.updated_at,
  });

  /// Factory constructor para criar CategoryDto a partir de Map (response do Supabase)
  factory CategoryDto.fromMap(Map<String, dynamic> map) {
    return CategoryDto(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      user_id: map['user_id'] as String,
      parent_id: map['parent_id'] as String?,
      color: map['color'] as String,
      icon: map['icon'] as String?,
      sort_order: map['sort_order'] as int,
      is_active: map['is_active'] as bool,
      created_at: map['created_at'] as String,
      updated_at: map['updated_at'] as String,
    );
  }

  /// Converte CategoryDto para Map (para enviar ao Supabase)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'user_id': user_id,
      'parent_id': parent_id,
      'color': color,
      'icon': icon,
      'sort_order': sort_order,
      'is_active': is_active,
      'created_at': created_at,
      'updated_at': updated_at,
    };
  }

  /// Factory constructor para criar CategoryDto a partir de JSON string
  factory CategoryDto.fromJson(String jsonString) {
    final Map<String, dynamic> map = json.decode(jsonString);
    return CategoryDto.fromMap(map);
  }

  /// Converte CategoryDto para JSON string (útil para cache)
  String toJson() {
    return json.encode(toMap());
  }

  /// Copy with para imutabilidade
  CategoryDto copyWith({
    String? name,
    String? description,
    String? user_id,
    String? parent_id,
    String? color,
    String? icon,
    int? sort_order,
    bool? is_active,
    String? updated_at,
  }) {
    return CategoryDto(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      user_id: user_id ?? this.user_id,
      parent_id: parent_id ?? this.parent_id,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      sort_order: sort_order ?? this.sort_order,
      is_active: is_active ?? this.is_active,
      created_at: created_at,
      updated_at: updated_at ?? this.updated_at,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CategoryDto && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'CategoryDto(id: $id, name: $name, user_id: $user_id, parent_id: $parent_id)';
  }
}
