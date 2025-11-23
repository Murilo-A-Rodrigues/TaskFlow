import 'dart:convert';

/// UserDto - Data Transfer Object que espelha a tabela users do Supabase
/// 
/// Esta classe representa os dados como eles são transferidos de e para
/// o Supabase/rede. Os nomes dos campos seguem snake_case (igual ao banco)
/// e os tipos são primitivos para facilitar serialização.
/// Segue o padrão DTO do documento "Modelo DTO e Mapeamento".
class UserDto {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? avatar_url;        // snake_case igual ao banco
  final bool is_active;           // snake_case igual ao banco
  final String created_at;        // ISO8601 String para o fio
  final String updated_at;        // ISO8601 String para sincronização
  final String? last_login_at;    // ISO8601 String ou null

  UserDto({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatar_url,
    required this.is_active,
    required this.created_at,
    required this.updated_at,
    this.last_login_at,
  });

  /// Factory constructor para criar UserDto a partir de Map (response do Supabase)
  factory UserDto.fromMap(Map<String, dynamic> map) {
    return UserDto(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String?,
      avatar_url: map['avatar_url'] as String?,
      is_active: map['is_active'] as bool,
      created_at: map['created_at'] as String,
      updated_at: map['updated_at'] as String,
      last_login_at: map['last_login_at'] as String?,
    );
  }

  /// Converte UserDto para Map (para enviar ao Supabase)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'avatar_url': avatar_url,
      'is_active': is_active,
      'created_at': created_at,
      'updated_at': updated_at,
      'last_login_at': last_login_at,
    };
  }

  /// Factory constructor para criar UserDto a partir de JSON string
  factory UserDto.fromJson(String jsonString) {
    final Map<String, dynamic> map = json.decode(jsonString);
    return UserDto.fromMap(map);
  }

  /// Converte UserDto para JSON string (útil para cache)
  String toJson() {
    return json.encode(toMap());
  }

  /// Copy with para imutabilidade
  UserDto copyWith({
    String? name,
    String? email,
    String? phone,
    String? avatar_url,
    bool? is_active,
    String? updated_at,
    String? last_login_at,
  }) {
    return UserDto(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatar_url: avatar_url ?? this.avatar_url,
      is_active: is_active ?? this.is_active,
      created_at: created_at,
      updated_at: updated_at ?? this.updated_at,
      last_login_at: last_login_at ?? this.last_login_at,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserDto && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'UserDto(id: $id, name: $name, email: $email, is_active: $is_active)';
  }
}
